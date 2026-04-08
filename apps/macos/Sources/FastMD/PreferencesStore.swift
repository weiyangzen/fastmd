import Foundation

/// Thin `UserDefaults` wrapper for the two user-facing trigger toggles.
///
/// The store owns nothing — callers read on demand and write-through to
/// `UserDefaults.standard`. Coordinator and menu bar keep their own cached
/// view and re-read after every mutation.
///
/// Defaults on first launch: hover trigger on, space trigger on.
enum PreferencesStore {
    enum Keys {
        static let hoverTriggerEnabled = "fastmd.hoverTriggerEnabled"
        static let spaceTriggerEnabled = "fastmd.spaceTriggerEnabled"
    }

    static var hoverTriggerEnabled: Bool {
        get { boolValue(forKey: Keys.hoverTriggerEnabled, default: true) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hoverTriggerEnabled) }
    }

    static var spaceTriggerEnabled: Bool {
        get { boolValue(forKey: Keys.spaceTriggerEnabled, default: true) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.spaceTriggerEnabled) }
    }

    private static func boolValue(forKey key: String, default defaultValue: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }
}
