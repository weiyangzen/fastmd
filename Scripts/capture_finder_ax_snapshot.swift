#!/usr/bin/env swift

import AppKit
import ApplicationServices
import Darwin
import Foundation

let directPathAttributeNames = ["AXFilename", "AXPath", "AXDocument", "AXURL"]
let titleAttributeNames = ["AXTitle", "AXValue", "AXDescription", "AXLabel", "AXHelp"]
let rowRoleNames = ["AXRow", "AXOutlineRow", "AXCell"]
let maxLineageDepth = 12
let maxSubtreeDepth = 3
let maxSubtreeNodes = 48
let maxAncestorSubtrees = 6
let maxExpandedSearchNodes = 180

func usage() {
    let text = """
    Usage:
      Scripts/capture_finder_ax_snapshot.swift [--delay seconds] [--output path]

    Example:
      Scripts/capture_finder_ax_snapshot.swift --delay 5

    Start the command, switch to Finder, keep the cursor over the target item,
    and wait for the delayed capture to finish.
    """
    print(text)
}

func parseArguments() -> (delay: TimeInterval, outputURL: URL)? {
    let scriptURL = URL(fileURLWithPath: #filePath)
    let repoRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    let defaultOutputURL = repoRoot
        .appendingPathComponent("Tests/Fixtures/FinderAX", isDirectory: true)
        .appendingPathComponent("finder-ax-snapshot-\(formatter.string(from: Date())).json")

    var delay: TimeInterval = 5
    var outputURL = defaultOutputURL

    var index = 1
    while index < CommandLine.arguments.count {
        let argument = CommandLine.arguments[index]
        switch argument {
        case "--delay":
            index += 1
            guard index < CommandLine.arguments.count, let parsedDelay = TimeInterval(CommandLine.arguments[index]) else {
                fputs("Missing or invalid value for --delay\n", stderr)
                return nil
            }
            delay = parsedDelay
        case "--output":
            index += 1
            guard index < CommandLine.arguments.count else {
                fputs("Missing value for --output\n", stderr)
                return nil
            }
            outputURL = URL(fileURLWithPath: CommandLine.arguments[index], relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)).standardizedFileURL
        case "--help", "-h":
            usage()
            exit(0)
        default:
            fputs("Unknown argument: \(argument)\n", stderr)
            return nil
        }
        index += 1
    }

    return (delay, outputURL)
}

func attributeValue(_ name: String, on element: AXUIElement) -> Any? {
    var object: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, name as CFString, &object)
    guard result == .success, let object else {
        return nil
    }
    return object
}

func attributeNames(on element: AXUIElement) -> [String] {
    var names: CFArray?
    let result = AXUIElementCopyAttributeNames(element, &names)
    guard result == .success, let names else {
        return []
    }

    return (names as? [String] ?? []).sorted()
}

func stringAttribute(_ name: String, on element: AXUIElement) -> String? {
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

func urlAttribute(_ name: String, on element: AXUIElement) -> String? {
    guard let value = attributeValue(name, on: element) else {
        return nil
    }

    if let url = value as? URL {
        return url.absoluteString
    }

    if let string = value as? String {
        return string
    }

    return nil
}

func parent(of element: AXUIElement) -> AXUIElement? {
    var object: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &object)
    guard result == .success, let object else {
        return nil
    }
    let parentElement: AXUIElement = object as! AXUIElement
    return parentElement
}

func children(of element: AXUIElement) -> [AXUIElement] {
    var object: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &object)
    guard result == .success, let object else {
        return []
    }
    return object as? [AXUIElement] ?? []
}

func elementLineage(_ element: AXUIElement) -> [AXUIElement] {
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

func breadthFirstElements(from root: AXUIElement, maxDepth: Int) -> [AXUIElement] {
    var result: [AXUIElement] = []
    var queue: [(element: AXUIElement, depth: Int)] = [(root, 0)]
    var seen = Set<String>()

    while !queue.isEmpty && result.count < maxSubtreeNodes {
        let next = queue.removeFirst()
        let identifier = String(describing: next.element)
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

func axHitTestPoints(for point: NSPoint) -> [NSPoint] {
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

func expandedContextElements(from lineage: [AXUIElement]) -> [AXUIElement] {
    var result: [AXUIElement] = []
    var seen = Set<String>()

    for ancestor in lineage.prefix(maxAncestorSubtrees) {
        let subtree = breadthFirstElements(from: ancestor, maxDepth: maxSubtreeDepth)
        for element in subtree {
            let identifier = String(describing: element)
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

func resolveDirectPath(from element: AXUIElement) -> String? {
    for attr in directPathAttributeNames {
        guard let rawValue = urlAttribute(attr, on: element)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty
        else {
            continue
        }
        return rawValue
    }
    return nil
}

func firstDirectPath(in elements: [AXUIElement]) -> String? {
    for element in elements {
        if let path = resolveDirectPath(from: element) {
            return path
        }
    }
    return nil
}

func extractMarkdownFileName(from value: String) -> String? {
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

func normalizeFileNameCandidate(_ rawValue: String) -> String? {
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

    if firstUsefulLine.hasPrefix("file://"),
       let fileURL = URL(string: firstUsefulLine),
       fileURL.isFileURL
    {
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

func firstMarkdownFileName(in elements: [AXUIElement]) -> String? {
    for element in elements {
        for name in titleAttributeNames {
            guard let rawValue = stringAttribute(name, on: element),
                  let normalizedValue = normalizeFileNameCandidate(rawValue)
            else {
                continue
            }

            if normalizedValue.lowercased().hasSuffix(".md") {
                return normalizedValue
            }
        }
    }

    return nil
}

func jsonValue(_ value: String?) -> Any {
    value ?? NSNull()
}

func nodeSnapshot(_ element: AXUIElement, index: Int) -> [String: Any] {
    var payload: [String: Any] = [
        "index": index,
        "debugIdentifier": String(describing: element),
    ]

    let interestingNames = [kAXRoleAttribute as String, kAXSubroleAttribute as String] + directPathAttributeNames + titleAttributeNames
    for name in interestingNames {
        if let string = stringAttribute(name, on: element) {
            payload[name] = string
        } else if let url = urlAttribute(name, on: element) {
            payload[name] = url
        }
    }

    let names = attributeNames(on: element)
    if !names.isEmpty {
        payload["availableAttributes"] = names
    }

    return payload
}

func firstLikelyListRow(in lineage: [AXUIElement]) -> AXUIElement? {
    lineage.first { element in
        guard let role = stringAttribute(kAXRoleAttribute as String, on: element) else {
            return false
        }
        return rowRoleNames.contains(role)
    }
}

guard let arguments = parseArguments() else {
    usage()
    exit(1)
}

guard AXIsProcessTrusted() else {
    fputs("Accessibility permission is required for AX snapshot capture.\n", stderr)
    exit(1)
}

print("Capture starts in \(arguments.delay) seconds.")
print("Switch to Finder, keep it frontmost, and rest the cursor over the target item.")
fflush(stdout)
Thread.sleep(forTimeInterval: arguments.delay)

let point = NSEvent.mouseLocation
let systemWide = AXUIElementCreateSystemWide()
var element: AXUIElement?
var hitPoint = point
var finalResult: AXError = .failure

for candidatePoint in axHitTestPoints(for: point) {
    var object: AXUIElement?
    let result = AXUIElementCopyElementAtPosition(systemWide, Float(candidatePoint.x), Float(candidatePoint.y), &object)
    if result == .success, let object {
        element = object
        hitPoint = candidatePoint
        finalResult = result
        break
    }
    finalResult = result
}

guard let element else {
    fputs("Failed to capture AX element at cursor. AX error code: \(finalResult.rawValue)\n", stderr)
    exit(1)
}

let lineage = elementLineage(element)
let rowElement = firstLikelyListRow(in: lineage)
let subtreeRoot = rowElement ?? element
let subtree = breadthFirstElements(from: subtreeRoot, maxDepth: maxSubtreeDepth)
let ancestorContext = expandedContextElements(from: lineage)

let formatter = ISO8601DateFormatter()
let payload: [String: Any] = [
    "capturedAt": formatter.string(from: Date()),
    "frontmostBundleID": NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown",
    "screenPoint": [
        "x": point.x,
        "y": point.y,
    ],
    "axHitTestPoint": [
        "x": hitPoint.x,
        "y": hitPoint.y,
    ],
    "analysis": [
        "rowFoundInLineage": rowElement != nil,
        "subtreeStrategy": rowElement == nil ? "hitElementOnly" : "lineageRowSubtree",
        "lineageFirstDirectPath": jsonValue(firstDirectPath(in: lineage)),
        "lineageFirstMarkdownFileName": jsonValue(firstMarkdownFileName(in: lineage)),
        "subtreeFirstDirectPath": jsonValue(firstDirectPath(in: subtree)),
        "subtreeFirstMarkdownFileName": jsonValue(firstMarkdownFileName(in: subtree)),
        "ancestorContextFirstDirectPath": jsonValue(firstDirectPath(in: ancestorContext)),
        "ancestorContextFirstMarkdownFileName": jsonValue(firstMarkdownFileName(in: ancestorContext)),
    ],
    "lineage": lineage.enumerated().map { nodeSnapshot($0.element, index: $0.offset) },
    "ancestorContext": ancestorContext.enumerated().map { nodeSnapshot($0.element, index: $0.offset) },
    "subtreeRoot": String(describing: subtreeRoot),
    "subtree": subtree.enumerated().map { nodeSnapshot($0.element, index: $0.offset) },
]

try FileManager.default.createDirectory(at: arguments.outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
try data.write(to: arguments.outputURL, options: .atomic)

print("Saved AX snapshot to \(arguments.outputURL.path)")
