@preconcurrency import ApplicationServices
import Foundation

enum AccessibilityPermissionManager {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func ensureTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
