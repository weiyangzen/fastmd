import AppKit
@preconcurrency import ApplicationServices
import Foundation

/// Outcome of resolving Finder's current selection for Space-trigger preview.
///
/// The CGEventTap callback reads this via `FinderSelectionSnapshot` from a
/// non-main thread, so the enum (and any value it carries) must be Sendable.
/// The three states map directly to tap policy:
///
/// - `.unknown` — fail-open. Pass Space through to Quick Look. We have not
///   resolved selection yet, or we have reason to believe the cache is stale.
/// - `.nonMarkdown` — fail-open. Pass Space through to Quick Look.
/// - `.markdown(url:)` — fail-closed. Swallow Space and dispatch a toggle to
///   the coordinator on the main actor.
enum FinderSelectionState: Sendable, Equatable {
    case unknown
    case nonMarkdown
    case markdown(url: URL)
}

/// Lock-free-to-read snapshot of what the resolver currently knows about
/// Finder and user intent. Held in `SelectionSnapshotHolder` and refreshed
/// only on the main actor; readable from any thread via the holder.
///
/// Every store bumps `generation`, so consumers can distinguish "same
/// selection seen twice" from "a newer decision landed".
struct FinderSelectionSnapshot: Sendable {
    let state: FinderSelectionState
    let finderPid: pid_t
    /// True when Finder's focused AX element is a text input — rename field,
    /// search field, path bar editor, etc. Even with a markdown file selected,
    /// Space must pass through when this is true so the user can type in the
    /// text field. Always false until AX observer integration lands.
    let isFinderEditingText: Bool
    /// Mirrors `PreferencesStore.spaceTriggerEnabled`. The tap checks this
    /// synchronously instead of reaching across threads into the store.
    let spaceTriggerEnabled: Bool
    /// Monotonic counter across all store operations.
    let generation: UInt64

    static let empty = FinderSelectionSnapshot(
        state: .unknown,
        finderPid: 0,
        isFinderEditingText: false,
        spaceTriggerEnabled: false,
        generation: 0
    )
}

/// Thread-safe holder for the latest `FinderSelectionSnapshot`.
///
/// Read-mostly usage from the CGEventTap thread, written from main. Uses
/// `NSLock` rather than `OSAllocatedUnfairLock` to avoid pulling in the
/// `os` allocated-lock API surface here; the struct is tiny and the critical
/// sections copy a 48-byte value, so contention is a non-issue.
final class SelectionSnapshotHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var value: FinderSelectionSnapshot = .empty

    var current: FinderSelectionSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ new: FinderSelectionSnapshot) {
        lock.lock()
        defer { lock.unlock() }
        value = new
    }
}

/// Owns the Finder selection cache that the Space tap reads synchronously.
///
/// Two-tier refresh pipeline:
///
/// 1. NSWorkspace activation / launch / termination notifications catch the
///    cross-process events (user brought Finder forward, Finder relaunched).
/// 2. An `AXObserver` attached to Finder's process catches the intra-process
///    events: focused window changed, focused UI element changed, main
///    window changed. Selection changes via keyboard arrows typically fire
///    focused-UI-element-changed on Finder; clicks on other rows also fire.
///
/// Both paths funnel into the same 50ms debounced refresh, which runs an
/// AppleScript query for the first .md in the current Finder selection.
///
/// Not covered yet: anchor geometry for the preview position policy. That
/// lands together with coordinator wiring in a follow-up.
@MainActor
final class FinderSelectionResolver {
    let snapshotHolder = SelectionSnapshotHolder()

    private var generationCounter: UInt64 = 0
    private var finderPid: pid_t = 0
    private var spaceTriggerEnabled: Bool = PreferencesStore.spaceTriggerEnabled
    private var pendingRefreshWorkItem: DispatchWorkItem?
    private let refreshDebounce: TimeInterval = 0.05
    /// Flips to true the first time the coordinator calls `activate()`,
    /// which only happens after Accessibility trust is confirmed. Guards
    /// any AX API access — without trust, AX calls silently fail with
    /// kAXErrorAPIDisabled and leave a dead observer behind.
    private var isActivated: Bool = false

    private var axObserver: AXObserver?
    private var axFinderElement: AXUIElement?
    private var latestIsEditingText: Bool = false

    /// Notifications that we register on the Finder application element.
    /// Selection changes in the file list typically surface as either a
    /// focused-UI-element change (arrow-key navigation moves AX focus to
    /// the new row) or as a main-window change (tab switch, Cmd+` cycle).
    private let axAppLevelNotifications: [String] = [
        kAXFocusedUIElementChangedNotification,
        kAXFocusedWindowChangedNotification,
        kAXMainWindowChangedNotification,
        kAXSelectedChildrenChangedNotification,
        kAXWindowCreatedNotification,
    ]

    /// Focused-element roles that FastMD treats as "user is typing in
    /// Finder" — Space must pass through to the text field, and Esc must
    /// not be hijacked. The list is intentionally broad: false positives
    /// only cost us a pass-through, which is the fail-open direction.
    private let editingTextRoleNames: Set<String> = [
        "AXTextField",
        "AXTextArea",
        "AXComboBox",
        "AXSearchField",
    ]

    /// First .md in the selection, or the first item overall if none of the
    /// selection is Markdown. Returning a non-Markdown path lets the resolver
    /// still mark the state `.nonMarkdown` (so the tap passes Space through)
    /// without a second AppleScript round-trip.
    private let selectionScript: NSAppleScript? = NSAppleScript(source: """
    tell application "Finder"
        if (count of Finder windows) is 0 then return ""
        try
            set theSelection to selection
        on error
            return ""
        end try
        if (count of theSelection) is 0 then return ""
        repeat with theItem in theSelection
            try
                set itemPath to POSIX path of (theItem as alias)
                if itemPath ends with ".md" or itemPath ends with ".MD" then
                    return itemPath
                end if
            end try
        end repeat
        try
            return POSIX path of ((item 1 of theSelection) as alias)
        on error
            return ""
        end try
    end tell
    """)

    init() {
        installWorkspaceObservers()
        refreshFinderPid()
        // Intentionally DO NOT attach the AX observer here. The resolver is
        // constructed as a stored property on the coordinator, which in turn
        // is a stored property on AppDelegate — so init() runs before
        // applicationDidFinishLaunching and therefore before the process has
        // been confirmed Accessibility-trusted. Any AX call made before the
        // trust check returns kAXErrorAPIDisabled (-25211), which would leave
        // us with a dead observer for the rest of the session. Trust-gated
        // attachment happens in `activate()`, which the coordinator calls
        // from its own start() right after the trust check succeeds.
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    /// Called by the coordinator once the process has confirmed Accessibility
    /// trust. Installs the AX observer on Finder and triggers an initial
    /// selection refresh. Safe to call multiple times; a subsequent call is a
    /// no-op unless the resolver currently has no AX observer attached.
    func activate() {
        isActivated = true
        refreshFinderPid()
        if finderPid != 0, axObserver == nil {
            attachAXObserver(to: finderPid)
        }
        scheduleRefresh(reason: "activate")
    }

    func setSpaceTriggerEnabled(_ enabled: Bool) {
        guard spaceTriggerEnabled != enabled else { return }
        spaceTriggerEnabled = enabled
        scheduleRefresh(reason: "spaceTriggerEnabled=\(enabled)")
    }

    /// Force a refresh on demand. Used by the coordinator right before it
    /// asks the resolver anything at startup, and by tests.
    func refreshNow(reason: String) {
        performRefresh(reason: reason)
    }

    // MARK: - Workspace observers

    private func installWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(
            self,
            selector: #selector(frontAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(appTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    @objc
    private func frontAppChanged() {
        scheduleRefresh(reason: "frontmost app changed")
    }

    @objc
    private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.finder"
        else { return }
        finderPid = app.processIdentifier
        RuntimeLogger.log("FinderSelectionResolver: Finder launched pid=\(finderPid)")
        attachAXObserver(to: finderPid)
        scheduleRefresh(reason: "Finder launched")
    }

    @objc
    private func appTerminated(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == "com.apple.finder"
        else { return }
        RuntimeLogger.log("FinderSelectionResolver: Finder terminated pid=\(finderPid)")
        detachAXObserver()
        finderPid = 0
        latestIsEditingText = false
        storeSnapshot(state: .unknown, isEditingText: false, reason: "Finder terminated")
    }

    private func refreshFinderPid() {
        let runningFinder = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.finder")
            .first
        finderPid = runningFinder?.processIdentifier ?? 0
    }

    // MARK: - Refresh pipeline

    private func scheduleRefresh(reason: String) {
        pendingRefreshWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.performRefresh(reason: reason)
        }
        pendingRefreshWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + refreshDebounce, execute: work)
    }

    private func performRefresh(reason: String) {
        if finderPid == 0 {
            refreshFinderPid()
        }

        // Self-heal: if Accessibility trust was granted after init (the
        // common case on first launch) or the observer dropped, reattach
        // now. AX calls only succeed once the process is trusted, so this
        // is also our retry after a permission grant. Skipped entirely
        // before activate() has been called: at that point the process is
        // still waiting for trust, and any AX call would silently fail.
        if isActivated && finderPid != 0 && axObserver == nil {
            attachAXObserver(to: finderPid)
        }

        guard finderPid != 0 else {
            storeSnapshot(state: .unknown, isEditingText: false, reason: "\(reason) (Finder not running)")
            return
        }

        let path = queryFinderSelectionPath()
        let state = classify(rawPath: path)
        latestIsEditingText = probeEditingText()
        storeSnapshot(state: state, isEditingText: latestIsEditingText, reason: reason)
    }

    private func queryFinderSelectionPath() -> String? {
        guard let script = selectionScript else {
            RuntimeLogger.log("FinderSelectionResolver: selection AppleScript failed to compile.")
            return nil
        }
        var error: NSDictionary?
        let value = script.executeAndReturnError(&error)
        if let error {
            RuntimeLogger.log("FinderSelectionResolver: selection AppleScript error: \(error)")
            return nil
        }
        let path = value.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return path.isEmpty ? nil : path
    }

    private func classify(rawPath: String?) -> FinderSelectionState {
        guard let rawPath else { return .nonMarkdown }
        let url = URL(fileURLWithPath: rawPath).standardizedFileURL
        guard url.pathExtension.lowercased() == "md" else {
            return .nonMarkdown
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else {
            return .nonMarkdown
        }
        return .markdown(url: url)
    }

    private func storeSnapshot(state: FinderSelectionState, isEditingText: Bool, reason: String) {
        generationCounter &+= 1
        let snapshot = FinderSelectionSnapshot(
            state: state,
            finderPid: finderPid,
            isFinderEditingText: isEditingText,
            spaceTriggerEnabled: spaceTriggerEnabled,
            generation: generationCounter
        )
        snapshotHolder.store(snapshot)

        let stateText: String
        switch state {
        case .unknown: stateText = "unknown"
        case .nonMarkdown: stateText = "nonMarkdown"
        case .markdown(let url): stateText = "markdown(\(url.lastPathComponent))"
        }
        RuntimeLogger.log(
            "FinderSelectionResolver: gen=\(generationCounter) state=\(stateText) editingText=\(isEditingText) pid=\(finderPid) reason=\"\(reason)\""
        )
    }

    // MARK: - AX observer

    fileprivate func handleAXNotification(_ notification: String) {
        // Called from the C callback dispatched back into the main actor.
        // Cheap path: update editing-text flag immediately from the current
        // focused element, then schedule a normal debounced refresh so the
        // AppleScript selection query runs coalesced with any sibling events.
        let editingText = probeEditingText()
        if editingText != latestIsEditingText {
            latestIsEditingText = editingText
            RuntimeLogger.log("FinderSelectionResolver: isEditingText -> \(editingText) via AX \(notification)")
        }
        scheduleRefresh(reason: "AX \(notification)")
    }

    private func attachAXObserver(to pid: pid_t) {
        detachAXObserver()

        var observer: AXObserver?
        let createResult = AXObserverCreate(pid, finderSelectionResolverAXCallback, &observer)
        guard createResult == .success, let observer else {
            RuntimeLogger.log(
                "FinderSelectionResolver: AXObserverCreate failed for pid=\(pid) result=\(createResult.rawValue)"
            )
            return
        }

        let finderElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        var succeeded = 0
        for notification in axAppLevelNotifications {
            let addResult = AXObserverAddNotification(
                observer,
                finderElement,
                notification as CFString,
                refcon
            )
            if addResult == .success || addResult == .notificationAlreadyRegistered {
                succeeded += 1
            } else {
                RuntimeLogger.log(
                    "FinderSelectionResolver: AXObserverAddNotification failed for \(notification) result=\(addResult.rawValue)"
                )
            }
        }

        guard succeeded > 0 else {
            // Every notification registration failed. This usually means
            // kAXErrorAPIDisabled — the process is not Accessibility-trusted
            // yet. Discard the observer so performRefresh will retry on the
            // next refresh cycle.
            RuntimeLogger.log(
                "FinderSelectionResolver: AX observer dropped because no notification could be registered for pid=\(pid). Will retry."
            )
            return
        }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )

        axObserver = observer
        axFinderElement = finderElement
        RuntimeLogger.log(
            "FinderSelectionResolver: AX observer attached to pid=\(pid) (\(succeeded)/\(axAppLevelNotifications.count) notifications)"
        )
    }

    private func detachAXObserver() {
        guard let observer = axObserver else { return }
        CFRunLoopRemoveSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )
        if let element = axFinderElement {
            for notification in axAppLevelNotifications {
                _ = AXObserverRemoveNotification(observer, element, notification as CFString)
            }
        }
        axObserver = nil
        axFinderElement = nil
        RuntimeLogger.log("FinderSelectionResolver: AX observer detached")
    }

    /// Read Finder's currently focused UI element and decide whether the
    /// user is typing into a text surface (rename field, search field, path
    /// bar editor). Best effort: any AX failure is treated as "not editing"
    /// so Space is still available as the preview trigger.
    private func probeEditingText() -> Bool {
        guard finderPid != 0 else { return false }
        let app = AXUIElementCreateApplication(finderPid)
        var focusedRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            app,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard result == .success, let focusedRef else { return false }
        let focusedElement = unsafeDowncast(focusedRef, to: AXUIElement.self)
        return isElementEditingText(focusedElement)
    }

    private func isElementEditingText(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        if roleResult == .success, let role = roleRef as? String, editingTextRoleNames.contains(role) {
            return true
        }

        var subroleRef: CFTypeRef?
        let subroleResult = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)
        if subroleResult == .success, let subrole = subroleRef as? String,
           subrole == "AXSearchField" || subrole == "AXTextField"
        {
            return true
        }

        return false
    }
}

// MARK: - AX observer C callback

/// Free function matching the `AXObserverCallback` C signature. The refcon
/// carries an unretained `FinderSelectionResolver`; we bounce the call back
/// to the main actor so the handler can touch isolated state safely.
private let finderSelectionResolverAXCallback: AXObserverCallback = {
    _, _, notification, refcon in
    guard let refcon else { return }
    let resolver = Unmanaged<FinderSelectionResolver>
        .fromOpaque(refcon)
        .takeUnretainedValue()
    let notificationName = notification as String
    Task { @MainActor in
        resolver.handleAXNotification(notificationName)
    }
}
