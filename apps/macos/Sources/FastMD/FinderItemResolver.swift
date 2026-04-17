import AppKit
import ApplicationServices
import Foundation

struct HoveredMarkdownItem: Equatable {
    let fileURL: URL
    let elementDescription: String
}

private struct AXElementScore: Comparable {
    let containsPoint: Bool
    let verticalDistance: CGFloat
    let horizontalDistance: CGFloat
    let area: CGFloat

    static func < (lhs: AXElementScore, rhs: AXElementScore) -> Bool {
        if lhs.containsPoint != rhs.containsPoint {
            return lhs.containsPoint && !rhs.containsPoint
        }
        if lhs.verticalDistance != rhs.verticalDistance {
            return lhs.verticalDistance < rhs.verticalDistance
        }
        if lhs.horizontalDistance != rhs.horizontalDistance {
            return lhs.horizontalDistance < rhs.horizontalDistance
        }
        return lhs.area < rhs.area
    }
}

@MainActor
final class FinderItemResolver {
    private let directPathAttributeNames = ["AXFilename", "AXPath", "AXDocument", "AXURL", "AXFileURL"]
    private let titleAttributeNames = ["AXTitle", "AXValue", "AXDescription", "AXLabel", "AXHelp", "AXFilename"]
    private let childAttributeNames = [
        kAXChildrenAttribute as String,
        "AXVisibleChildren",
        "AXChildrenInNavigationOrder",
        "AXRows",
        "AXContents",
        "AXUIElements",
        "AXSelectedChildren",
    ]
    private let rowRoleNames = ["AXRow", "AXOutlineRow"]
    private let cellRoleNames = ["AXCell"]
    // AXImage is the icon itself; AXStaticText is the filename label beside it.
    // Labels are often visually larger than the icon, so hover hit-tests land on
    // the text element more often than on the image. Both should anchor on the
    // enclosing group and BFS siblings.
    private let iconHitRoleNames = ["AXImage", "AXStaticText"]
    private let nonListAnchorRoleNames = ["AXGroup", "AXImage", "AXStaticText", "AXButton", "AXOutline"]
    private let maxLineageDepth = 12
    private let maxSubtreeDepth = 3
    private let maxSubtreeNodes = 48
    private let maxAncestorSubtrees = 6
    private let maxExpandedSearchNodes = 180
    private let finderDirectoryCacheTTL: TimeInterval = 0.75
    private var cachedFinderDirectoryURL: URL?
    private var cachedFinderDirectoryAt: Date?

    func resolveMarkdown(at screenPoint: NSPoint) -> HoveredMarkdownItem? {
        let frontmostBundleID = frontmostAppBundleID() ?? "unknown"
        guard frontmostBundleID == "com.apple.finder" else {
            RuntimeLogger.log("Resolver skipped because Finder is not frontmost. frontmostBundleID=\(frontmostBundleID)")
            return nil
        }

        guard let element = element(at: screenPoint) else {
            RuntimeLogger.log(
                String(
                    format: "Resolver failed: no AX element at screen point x=%.1f y=%.1f",
                    screenPoint.x,
                    screenPoint.y
                )
            )
            return nil
        }

        let lineage = elementLineage(element)
        RuntimeLogger.log("Resolver AX lineage: \(debugDescription(for: lineage))")

        if let directPath = nearestDirectPath(in: lineage, near: screenPoint),
           let resolvedItem = resolvedMarkdownItem(from: directPath, description: "AX lineage direct path")
        {
            return resolvedItem
        }

        if let rowElement = firstLikelyListRow(in: lineage) {
            let rowSubtree = breadthFirstElements(from: rowElement, maxDepth: maxSubtreeDepth)
            RuntimeLogger.log("Resolver row subtree: \(debugDescription(for: rowSubtree, maxElements: 32))")

            if let directPath = nearestDirectPath(in: rowSubtree, near: screenPoint),
               let resolvedItem = resolvedMarkdownItem(from: directPath, description: "Finder row subtree direct path")
            {
                return resolvedItem
            }

            if let fileName = nearestMarkdownFileName(in: rowSubtree, near: screenPoint),
               let resolvedItem = resolvedMarkdownItem(fromCandidateName: fileName, description: "Finder row subtree file name")
            {
                return resolvedItem
            }
        }

        if let nonListAnchor = firstLikelyNonListAnchor(in: lineage) {
            let nonListSubtree = breadthFirstElements(from: nonListAnchor, maxDepth: maxSubtreeDepth)
            RuntimeLogger.log("Resolver non-list anchor subtree: \(debugDescription(for: nonListSubtree, maxElements: 24))")

            if let directPath = nearestDirectPath(in: nonListSubtree, near: screenPoint),
               let resolvedItem = resolvedMarkdownItem(from: directPath, description: "Finder non-list anchor direct path")
            {
                return resolvedItem
            }

            if let fileName = nearestMarkdownFileName(in: nonListSubtree, near: screenPoint),
               let resolvedItem = resolvedMarkdownItem(fromCandidateName: fileName, description: "Finder non-list anchor file name")
            {
                return resolvedItem
            }
        }

        let expandedContext = expandedContextElements(from: lineage)
        if !expandedContext.isEmpty {
            RuntimeLogger.log("Resolver ancestor-context subtree: \(debugDescription(for: expandedContext, maxElements: 40))")

            if let nearestRow = nearestLikelyListRow(in: expandedContext, near: screenPoint) {
                let rowSubtree = breadthFirstElements(from: nearestRow, maxDepth: maxSubtreeDepth)
                RuntimeLogger.log("Resolver nearest-row subtree: \(debugDescription(for: rowSubtree, maxElements: 32))")

                if let directPath = nearestDirectPath(in: rowSubtree, near: screenPoint),
                   let resolvedItem = resolvedMarkdownItem(from: directPath, description: "Ancestor nearest-row direct path")
                {
                    return resolvedItem
                }

                if let fileName = nearestMarkdownFileName(in: rowSubtree, near: screenPoint),
                   let resolvedItem = resolvedMarkdownItem(fromCandidateName: fileName, description: "Ancestor nearest-row file name")
                {
                    return resolvedItem
                }
            } else {
                if let directPath = nearestDirectPath(in: expandedContext, near: screenPoint),
                   let resolvedItem = resolvedMarkdownItem(from: directPath, description: "Ancestor-context direct path")
                {
                    return resolvedItem
                }

                if let fileName = nearestMarkdownFileName(in: expandedContext, near: screenPoint),
                   let resolvedItem = resolvedMarkdownItem(fromCandidateName: fileName, description: "Ancestor-context file name")
                {
                    return resolvedItem
                }
            }
        }

        if let fileName = nearestMarkdownFileName(in: lineage, near: screenPoint),
           let resolvedItem = resolvedMarkdownItem(fromCandidateName: fileName, description: "AX lineage title fallback")
        {
            return resolvedItem
        }

        RuntimeLogger.log("Resolver failed after AX lineage and subtree search.")
        return nil
    }

    private func resolvedMarkdownItem(from url: URL, description: String) -> HoveredMarkdownItem? {
        let standardizedURL = url.standardizedFileURL
        guard standardizedURL.isFileURL else {
            RuntimeLogger.log("Rejected non-file URL from \(description): \(standardizedURL.absoluteString)")
            return nil
        }
        guard standardizedURL.pathExtension.lowercased() == "md" else {
            RuntimeLogger.log("Rejected non-Markdown path from \(description): \(standardizedURL.path)")
            return nil
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory) else {
            RuntimeLogger.log("Rejected missing path from \(description): \(standardizedURL.path)")
            return nil
        }
        guard !isDirectory.boolValue else {
            RuntimeLogger.log("Rejected directory from \(description): \(standardizedURL.path)")
            return nil
        }

        return HoveredMarkdownItem(fileURL: standardizedURL, elementDescription: description)
    }

    private func resolvedMarkdownItem(fromCandidateName candidateName: String, description: String) -> HoveredMarkdownItem? {
        guard let normalizedName = normalizeFileNameCandidate(candidateName) else {
            RuntimeLogger.log("Rejected empty file-name candidate from \(description): \(candidateName)")
            return nil
        }

        guard let directory = currentFinderDirectory() else {
            RuntimeLogger.log("Could not resolve front Finder directory while handling candidate \(normalizedName)")
            return nil
        }

        let candidateURL = directory.appendingPathComponent(normalizedName)
        guard let resolvedItem = resolvedMarkdownItem(from: candidateURL, description: description) else {
            RuntimeLogger.log("Joined Finder directory and candidate name but no Markdown file exists: \(candidateURL.path)")
            return nil
        }

        return resolvedItem
    }

    private func frontmostAppBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func element(at point: NSPoint) -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        let candidatePoints = axHitTestPoints(for: point)

        for candidatePoint in candidatePoints {
            var object: AXUIElement?
            let result = AXUIElementCopyElementAtPosition(systemWide, Float(candidatePoint.x), Float(candidatePoint.y), &object)
            if result == .success, let object {
                if candidatePoint != point {
                    RuntimeLogger.log(
                        String(
                            format: "Resolver AX hit-test succeeded after coordinate conversion. appKitPoint=(%.1f, %.1f) axPoint=(%.1f, %.1f)",
                            point.x,
                            point.y,
                            candidatePoint.x,
                            candidatePoint.y
                        )
                    )
                }
                return object
            }
        }

        return nil
    }

    private func currentFinderDirectory() -> URL? {
        if let cachedFinderDirectoryURL,
           let cachedFinderDirectoryAt,
           Date().timeIntervalSince(cachedFinderDirectoryAt) <= finderDirectoryCacheTTL
        {
            return cachedFinderDirectoryURL
        }

        let source = """
        tell application "Finder"
            if (count of Finder windows) is 0 then return ""
            set theWindow to front Finder window
            try
                return POSIX path of (target of theWindow as alias)
            on error
                return ""
            end try
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            RuntimeLogger.log("Failed to construct AppleScript for current Finder directory.")
            return nil
        }

        var error: NSDictionary?
        let value = script.executeAndReturnError(&error)
        guard error == nil else {
            RuntimeLogger.log("AppleScript error while reading Finder directory: \(error!)")
            return nil
        }

        let path = value.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !path.isEmpty else {
            RuntimeLogger.log("Finder directory AppleScript returned an empty path.")
            return nil
        }

        RuntimeLogger.log("Front Finder directory resolved to \(path)")
        let url = URL(fileURLWithPath: path, isDirectory: true)
        cachedFinderDirectoryURL = url
        cachedFinderDirectoryAt = Date()
        return url
    }

    private func nearestDirectPath(in elements: [AXUIElement], near screenPoint: NSPoint) -> URL? {
        var bestMatch: (url: URL, attributeName: String, score: AXElementScore)?

        for element in elements {
            for attributeName in directPathAttributeNames {
                guard let path = urlAttribute(attributeName, on: element) else {
                    continue
                }

                let score = score(for: element, near: screenPoint)
                if let bestMatch, !(score < bestMatch.score) {
                    continue
                }

                bestMatch = (path, attributeName, score)
            }
        }

        if let bestMatch {
            RuntimeLogger.log(
                "Found nearest direct AX path candidate in \(bestMatch.attributeName): \(bestMatch.url.path)"
            )
        }

        return bestMatch?.url
    }

    private func nearestMarkdownFileName(in elements: [AXUIElement], near screenPoint: NSPoint) -> String? {
        var bestMatch: (fileName: String, attributeName: String, score: AXElementScore)?

        for element in elements {
            for name in titleAttributeNames {
                guard let rawValue = stringAttribute(name, on: element) else {
                    continue
                }
                guard let normalizedValue = normalizeFileNameCandidate(rawValue) else {
                    continue
                }
                if normalizedValue.lowercased().hasSuffix(".md") {
                    let score = score(for: element, near: screenPoint)
                    if let bestMatch, !(score < bestMatch.score) {
                        continue
                    }

                    bestMatch = (normalizedValue, name, score)
                }
            }
        }

        if let bestMatch {
            RuntimeLogger.log(
                "Found nearest Markdown file-name candidate in \(bestMatch.attributeName): \(bestMatch.fileName)"
            )
        }

        return bestMatch?.fileName
    }

    private func normalizeFileNameCandidate(_ rawValue: String) -> String? {
        let trimmedValue = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{0}", with: "")

        guard !trimmedValue.isEmpty else {
            return nil
        }

        let firstUsefulLine = trimmedValue
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? trimmedValue

        if firstUsefulLine.hasPrefix("file://"), let fileURL = URL(string: firstUsefulLine), fileURL.isFileURL {
            return fileURL.lastPathComponent
        }

        if firstUsefulLine.hasPrefix("/") {
            return URL(fileURLWithPath: firstUsefulLine).lastPathComponent
        }

        if let extractedMarkdownName = extractMarkdownFileName(from: firstUsefulLine) {
            return extractedMarkdownName
        }

        return firstUsefulLine
    }

    private func extractMarkdownFileName(from value: String) -> String? {
        let pattern = #"(?i)([^/\n]+?\.md)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, options: [], range: range),
              let nameRange = Range(match.range(at: 1), in: value)
        else {
            return nil
        }

        return String(value[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func firstLikelyListRow(in lineage: [AXUIElement]) -> AXUIElement? {
        if let row = lineage.first(where: { hasRole($0, matchingAnyOf: rowRoleNames) }) {
            return row
        }

        return lineage.first { element in
            hasRole(element, matchingAnyOf: cellRoleNames)
        }
    }

    /// Non-list Finder views expose item tiles inconsistently: sometimes the hit
    /// lands on an `AXImage`, sometimes on a label, and sometimes directly on a
    /// grouping node. Prefer the immediate parent for leaf icon/label hits, then
    /// fall back to the first near-lineage grouping role so icon/column-style
    /// layouts still give us a BFS root that includes sibling metadata.
    private func firstLikelyNonListAnchor(in lineage: [AXUIElement]) -> AXUIElement? {
        guard !lineage.isEmpty else { return nil }
        guard firstLikelyListRow(in: lineage) == nil else { return nil }

        let prefix = Array(lineage.prefix(4))
        for (index, element) in prefix.enumerated() {
            if index == 0, hasRole(element, matchingAnyOf: iconHitRoleNames), lineage.count >= 2 {
                return lineage[1]
            }
            if hasRole(element, matchingAnyOf: nonListAnchorRoleNames) {
                return element
            }
        }

        return lineage.count >= 2 ? lineage[1] : lineage.first
    }

    private func nearestLikelyListRow(in elements: [AXUIElement], near screenPoint: NSPoint) -> AXUIElement? {
        let rowCandidates = elements.filter { hasRole($0, matchingAnyOf: rowRoleNames) }
        if let row = nearestElement(in: rowCandidates, near: screenPoint) {
            return row
        }

        let cellCandidates = elements.filter { hasRole($0, matchingAnyOf: cellRoleNames) }
        return nearestElement(in: cellCandidates, near: screenPoint)
    }

    private func elementLineage(_ element: AXUIElement) -> [AXUIElement] {
        var lineage: [AXUIElement] = []
        var current: AXUIElement? = element
        var depth = 0

        while let node = current, depth < maxLineageDepth {
            lineage.append(node)
            current = parent(of: node)
            depth += 1
        }

        return lineage
    }

    private func breadthFirstElements(from root: AXUIElement, maxDepth: Int) -> [AXUIElement] {
        var result: [AXUIElement] = []
        var queue: [(element: AXUIElement, depth: Int)] = [(root, 0)]
        var headIndex = 0
        var seen = Set<UInt>()

        while headIndex < queue.count && result.count < maxSubtreeNodes {
            let next = queue[headIndex]
            headIndex += 1
            let identifier = elementIdentifier(next.element)
            guard seen.insert(identifier).inserted else {
                continue
            }

            result.append(next.element)

            guard next.depth < maxDepth else {
                continue
            }

            for child in children(of: next.element) {
                queue.append((child, next.depth + 1))
            }
        }

        return result
    }

    private func expandedContextElements(from lineage: [AXUIElement]) -> [AXUIElement] {
        var result: [AXUIElement] = []
        var seen = Set<UInt>()

        for ancestor in lineage.prefix(maxAncestorSubtrees) {
            let subtree = breadthFirstElements(from: ancestor, maxDepth: maxSubtreeDepth)
            for element in subtree {
                let identifier = elementIdentifier(element)
                guard seen.insert(identifier).inserted else {
                    continue
                }
                result.append(element)
                if result.count >= maxExpandedSearchNodes {
                    return result
                }
            }
        }

        return result
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var result: [AXUIElement] = []
        var seen = Set<UInt>()

        for attributeName in childAttributeNames {
            var object: CFTypeRef?
            let copyResult = AXUIElementCopyAttributeValue(element, attributeName as CFString, &object)
            guard copyResult == .success, let object else {
                continue
            }

            guard let candidates = object as? [AXUIElement] else {
                continue
            }

            for child in candidates {
                let identifier = elementIdentifier(child)
                guard seen.insert(identifier).inserted else {
                    continue
                }
                result.append(child)
            }
        }

        return result
    }

    private func parent(of element: AXUIElement) -> AXUIElement? {
        var object: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &object)
        guard result == .success, let object else {
            return nil
        }
        let parentElement: AXUIElement = object as! AXUIElement
        return parentElement
    }

    private func elementIdentifier(_ element: AXUIElement) -> UInt {
        UInt(bitPattern: Unmanaged.passUnretained(element).toOpaque())
    }

    private func nearestElement(in elements: [AXUIElement], near screenPoint: NSPoint) -> AXUIElement? {
        var bestElement: AXUIElement?
        var bestScore: AXElementScore?

        for element in elements {
            let elementScore = score(for: element, near: screenPoint)
            if let bestScore, !(elementScore < bestScore) {
                continue
            }
            bestScore = elementScore
            bestElement = element
        }

        return bestElement
    }

    private func hasRole(_ element: AXUIElement, matchingAnyOf roles: [String]) -> Bool {
        guard let role = stringAttribute(kAXRoleAttribute as String, on: element) else {
            return false
        }
        return roles.contains(role)
    }

    private func score(for element: AXUIElement, near screenPoint: NSPoint) -> AXElementScore {
        guard let frame = frame(of: element) else {
            return AXElementScore(
                containsPoint: false,
                verticalDistance: .greatestFiniteMagnitude,
                horizontalDistance: .greatestFiniteMagnitude,
                area: .greatestFiniteMagnitude
            )
        }

        let containsPoint = frame.contains(screenPoint)
        let verticalDistance = axisDistance(screenPoint.y, min: frame.minY, max: frame.maxY)
        let horizontalDistance = axisDistance(screenPoint.x, min: frame.minX, max: frame.maxX)
        let area = max(frame.width * frame.height, 1)

        return AXElementScore(
            containsPoint: containsPoint,
            verticalDistance: verticalDistance,
            horizontalDistance: horizontalDistance,
            area: area
        )
    }

    private func axisDistance(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if value < min {
            return min - value
        }
        if value > max {
            return value - max
        }
        return 0
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        var position = CGPoint.zero
        var size = CGSize.zero

        var positionObject: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionObject)
        guard positionResult == .success,
              let positionObject,
              CFGetTypeID(positionObject) == AXValueGetTypeID()
        else {
            return nil
        }
        let positionValue = unsafeDowncast(positionObject, to: AXValue.self)
        guard AXValueGetType(positionValue) == .cgPoint,
              AXValueGetValue(positionValue, .cgPoint, &position)
        else {
            return nil
        }

        var sizeObject: CFTypeRef?
        let sizeResult = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeObject)
        guard sizeResult == .success,
              let sizeObject,
              CFGetTypeID(sizeObject) == AXValueGetTypeID()
        else {
            return nil
        }
        let sizeValue = unsafeDowncast(sizeObject, to: AXValue.self)
        guard AXValueGetType(sizeValue) == .cgSize,
              AXValueGetValue(sizeValue, .cgSize, &size)
        else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    private func axHitTestPoints(for point: NSPoint) -> [NSPoint] {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) else {
            return [point]
        }

        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return [point]
        }
        let displayID = CGDirectDisplayID(screenNumber.uint32Value)
        let displayBounds = CGDisplayBounds(displayID)

        let localX = point.x - screen.frame.minX
        let localYFromBottom = point.y - screen.frame.minY
        let convertedPoint = NSPoint(
            x: displayBounds.minX + localX,
            y: displayBounds.minY + (screen.frame.height - localYFromBottom)
        )

        if convertedPoint == point {
            return [point]
        }

        return [convertedPoint, point]
    }

    private func urlAttribute(_ name: String, on element: AXUIElement) -> URL? {
        guard let value = attributeValue(name, on: element) else {
            return nil
        }

        if let url = value as? URL, url.isFileURL {
            return url
        }

        if let path = value as? String {
            let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedPath.hasPrefix("/") {
                return URL(fileURLWithPath: trimmedPath)
            }
            if trimmedPath.hasPrefix("file://"), let url = URL(string: trimmedPath), url.isFileURL {
                return url
            }
        }

        return nil
    }

    private func stringAttribute(_ name: String, on element: AXUIElement) -> String? {
        guard let value = attributeValue(name, on: element) else {
            return nil
        }

        if let string = value as? String {
            return string
        }

        if let attributedString = value as? NSAttributedString {
            return attributedString.string
        }

        return nil
    }

    private func attributeValue(_ name: String, on element: AXUIElement) -> Any? {
        var object: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, name as CFString, &object)
        guard result == .success, let object else {
            return nil
        }
        return object
    }

    private func debugDescription(for elements: [AXUIElement], maxElements: Int? = nil) -> String {
        let slice = maxElements.map { Array(elements.prefix($0)) } ?? elements
        var output = slice.enumerated().map { index, element in
            "node\(index){\(elementSummary(element))}"
        }
        .joined(separator: " -> ")

        if let maxElements, elements.count > maxElements {
            output += " -> ...(\(elements.count - maxElements) more nodes)"
        }

        return output
    }

    private func elementSummary(_ element: AXUIElement) -> String {
        let interestingAttributes = [
            kAXRoleAttribute as String,
            kAXSubroleAttribute as String,
            "AXTitle",
            "AXValue",
            "AXDescription",
            "AXFilename",
            "AXPath",
            "AXDocument",
            "AXURL",
        ]

        let parts = interestingAttributes.compactMap { name -> String? in
            guard let value = debugValue(for: name, on: element) else {
                return nil
            }
            return "\(name)=\(value)"
        }

        return parts.isEmpty ? "no interesting AX attributes" : parts.joined(separator: ", ")
    }

    private func debugValue(for name: String, on element: AXUIElement) -> String? {
        if let url = urlAttribute(name, on: element) {
            return quote(url.path)
        }

        if let string = stringAttribute(name, on: element) {
            return quote(truncate(string))
        }

        return nil
    }

    private func truncate(_ value: String, limit: Int = 120) -> String {
        guard value.count > limit else {
            return value
        }
        return String(value.prefix(limit)) + "..."
    }

    private func quote(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}
