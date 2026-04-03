import AppKit
import ApplicationServices
import Foundation

struct HoveredMarkdownItem: Equatable {
    let fileURL: URL
    let elementDescription: String
}

@MainActor
final class FinderItemResolver {
    func resolveMarkdown(at screenPoint: NSPoint) -> HoveredMarkdownItem? {
        guard frontmostAppBundleID() == "com.apple.finder" else {
            return nil
        }

        guard let element = element(at: screenPoint) else {
            return nil
        }

        if let directPath = resolveDirectPath(from: element), directPath.pathExtension.lowercased() == "md" {
            return HoveredMarkdownItem(fileURL: directPath, elementDescription: "AX direct path")
        }

        guard let title = firstNonEmptyAttribute(in: elementLineage(element), names: ["AXTitle", "AXValue", "AXDescription"]) else {
            return nil
        }
        guard title.lowercased().hasSuffix(".md") else {
            return nil
        }

        guard let directory = currentFinderDirectory() else {
            return nil
        }

        let candidate = directory.appendingPathComponent(title)
        guard FileManager.default.fileExists(atPath: candidate.path) else {
            return nil
        }

        return HoveredMarkdownItem(fileURL: candidate, elementDescription: "Finder window target + AX title")
    }

    private func frontmostAppBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func element(at point: NSPoint) -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var object: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &object)
        guard result == .success, let object else {
            return nil
        }
        return object
    }

    private func currentFinderDirectory() -> URL? {
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
            return nil
        }

        var error: NSDictionary?
        let value = script.executeAndReturnError(&error)
        guard error == nil else {
            return nil
        }

        let path = value.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !path.isEmpty else {
            return nil
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private func resolveDirectPath(from element: AXUIElement) -> URL? {
        for attr in ["AXFilename", "AXPath", "AXDocument"] {
            if let path = stringAttribute(attr, on: element), path.hasPrefix("/") {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    private func elementLineage(_ element: AXUIElement) -> [AXUIElement] {
        var lineage: [AXUIElement] = []
        var current: AXUIElement? = element
        var depth = 0
        while let node = current, depth < 10 {
            lineage.append(node)
            current = parent(of: node)
            depth += 1
        }
        return lineage
    }

    private func firstNonEmptyAttribute(in lineage: [AXUIElement], names: [String]) -> String? {
        for node in lineage {
            for name in names {
                if let value = stringAttribute(name, on: node)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }

    private func parent(of element: AXUIElement) -> AXUIElement? {
        var object: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &object)
        guard result == .success, let object else {
            return nil
        }
        return (object as! AXUIElement)
    }

    private func stringAttribute(_ name: String, on element: AXUIElement) -> String? {
        var object: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, name as CFString, &object)
        guard result == .success, let object else {
            return nil
        }
        return object as? String
    }
}
