import AppKit
@preconcurrency import ApplicationServices
@preconcurrency import CoreGraphics
import Foundation

/// Thread-safe flag the Space tap callback reads synchronously to decide
/// whether an Esc press should be swallowed (only swallow when the preview
/// is visible). Separate from the selection snapshot because it reflects
/// FastMD's own state, not Finder's.
final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Bool

    init(_ initial: Bool) {
        self.value = initial
    }

    var current: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ new: Bool) {
        lock.lock()
        defer { lock.unlock() }
        value = new
    }
}

/// Holds a `CFRunLoop` reference that the Space tap thread publishes once
/// the tap is installed, so the main actor can later call `CFRunLoopStop`
/// on the same loop to shut it down. The CF type itself is not `Sendable`,
/// so we wrap it in an unchecked-Sendable lock-protected box.
final class CFRunLoopBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: CFRunLoop?

    var current: CFRunLoop? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ new: CFRunLoop?) {
        lock.lock()
        defer { lock.unlock() }
        value = new
    }
}

/// CGEventTap wrapper that intercepts Space and Escape when the user is in
/// Finder and has a Markdown file selected.
///
/// Threading model:
///
/// - Public API (`start`, `stop`, `setPreviewVisible`) is @MainActor.
/// - The CGEventTap lives on a dedicated `Thread` with its own CFRunLoop,
///   so the tap callback never competes with WebKit, AppKit animation, AX
///   traffic, or file loading for the main thread. A slow main thread is
///   one of the documented ways the OS disables an event tap.
/// - The C callback reads only three thread-safe inputs:
///     1. `SelectionSnapshotHolder.current` — the Finder selection snapshot
///        refreshed from the main actor.
///     2. `AtomicBool.current` — FastMD's preview-visible flag.
///     3. `CGEvent` fields such as keyCode, flags, autorepeat, and the
///        event target PID.
///   No AX, AppleScript, or filesystem access runs on the tap thread.
/// - When the callback decides to act it dispatches back to the main queue
///   so the coordinator's @MainActor methods run in the right isolation.
///
/// Pass-through policy ("fail-open", per Codex review):
///
/// - Unless ALL of the following are true, Space passes through to whichever
///   app has the key: keyDown not autorepeat, no modifier flags, event
///   target PID matches Finder, spaceTriggerEnabled, not editing text in
///   Finder, selection state is `.markdown`.
/// - Esc only swallows when preview is visible AND Finder is not editing
///   text. Never swallow Esc in a rename field, search field, or path bar.
@MainActor
final class SpaceKeyMonitor {
    var onSpacePressed: (@MainActor () -> Void)?
    var onEscapePressed: (@MainActor () -> Void)?

    private let snapshotHolder: SelectionSnapshotHolder
    private let previewVisible = AtomicBool(false)
    private let runLoopBox = CFRunLoopBox()

    private var tapThread: Thread?
    private var isRunningFlag = false

    init(snapshotHolder: SelectionSnapshotHolder) {
        self.snapshotHolder = snapshotHolder
    }

    var isRunning: Bool { isRunningFlag }

    func setPreviewVisible(_ visible: Bool) {
        previewVisible.store(visible)
    }

    func start() {
        guard !isRunningFlag else { return }
        guard CGPreflightListenEventAccess() || CGRequestListenEventAccess() else {
            RuntimeLogger.log(
                "SpaceKeyMonitor: Input Monitoring permission missing. Tap not started."
            )
            return
        }

        let context = SpaceKeyTapContext(
            snapshotHolder: snapshotHolder,
            previewVisible: previewVisible,
            onSpacePressed: { [weak self] in
                guard let self else { return }
                self.onSpacePressed?()
            },
            onEscapePressed: { [weak self] in
                guard let self else { return }
                self.onEscapePressed?()
            }
        )

        let box = runLoopBox
        let thread = Thread {
            Thread.current.name = "com.fastmd.space-tap"
            SpaceKeyMonitor.runTapLoop(context: context, runLoopBox: box)
        }
        thread.qualityOfService = QualityOfService.userInteractive
        tapThread = thread
        isRunningFlag = true
        thread.start()
        RuntimeLogger.log("SpaceKeyMonitor: tap thread launched")
    }

    func stop() {
        guard isRunningFlag else { return }
        isRunningFlag = false
        if let runLoop = runLoopBox.current {
            CFRunLoopStop(runLoop)
        }
        runLoopBox.store(nil)
        tapThread = nil
        RuntimeLogger.log("SpaceKeyMonitor: tap thread stopped")
    }

    // Runs on the dedicated tap thread. Creates the tap, publishes the run
    // loop reference via the thread-safe box so `stop()` can wake us, then
    // pumps the run loop until told to exit.
    private nonisolated static func runTapLoop(
        context: SpaceKeyTapContext,
        runLoopBox: CFRunLoopBox
    ) {
        let runLoop = CFRunLoopGetCurrent()

        // Retained: the SpaceKeyTapContext's lifetime is tied to the tap
        // thread. We release it once the run loop exits.
        let refcon = Unmanaged.passRetained(context).toOpaque()

        let eventsOfInterest = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventsOfInterest),
            callback: spaceKeyTapCallback,
            userInfo: refcon
        ) else {
            RuntimeLogger.log(
                "SpaceKeyMonitor: CGEvent.tapCreate returned nil (Input Monitoring or Accessibility probably missing)"
            )
            Unmanaged<SpaceKeyTapContext>.fromOpaque(refcon).release()
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        runLoopBox.store(runLoop)
        RuntimeLogger.log("SpaceKeyMonitor: tap created, entering run loop")
        CFRunLoopRun()
        RuntimeLogger.log("SpaceKeyMonitor: run loop exited")

        CFRunLoopRemoveSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: false)
        Unmanaged<SpaceKeyTapContext>.fromOpaque(refcon).release()
    }
}

// MARK: - Tap context and C callback

/// Minimal bundle of state the C callback needs. Held alive via a retained
/// Unmanaged pointer so the callback can read it without crossing actor
/// boundaries.
private final class SpaceKeyTapContext: @unchecked Sendable {
    let snapshotHolder: SelectionSnapshotHolder
    let previewVisible: AtomicBool
    let onSpacePressed: @MainActor () -> Void
    let onEscapePressed: @MainActor () -> Void

    init(
        snapshotHolder: SelectionSnapshotHolder,
        previewVisible: AtomicBool,
        onSpacePressed: @escaping @MainActor () -> Void,
        onEscapePressed: @escaping @MainActor () -> Void
    ) {
        self.snapshotHolder = snapshotHolder
        self.previewVisible = previewVisible
        self.onSpacePressed = onSpacePressed
        self.onEscapePressed = onEscapePressed
    }
}

private let spaceKeyCode: Int64 = 49
private let escapeKeyCode: Int64 = 53

private let modifierMask: CGEventFlags = [
    .maskCommand,
    .maskAlternate,
    .maskControl,
    .maskSecondaryFn,
]

/// C callback. Runs on the tap thread. Keep it allocation-free and
/// allocation-adjacent-free: the OS will disable a slow tap.
private let spaceKeyTapCallback: CGEventTapCallBack = {
    _, type, event, refcon in

    // Tap lifecycle events — re-enable ourselves after a timeout and
    // bail on explicit user disable.
    if type == .tapDisabledByTimeout {
        if let refcon {
            let ctx = Unmanaged<SpaceKeyTapContext>
                .fromOpaque(refcon)
                .takeUnretainedValue()
            _ = ctx  // silence unused warning in release builds
        }
        return Unmanaged.passUnretained(event)
    }
    if type == .tapDisabledByUserInput {
        return Unmanaged.passUnretained(event)
    }
    if type != .keyDown {
        return Unmanaged.passUnretained(event)
    }

    guard let refcon else {
        return Unmanaged.passUnretained(event)
    }
    let ctx = Unmanaged<SpaceKeyTapContext>
        .fromOpaque(refcon)
        .takeUnretainedValue()

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    if keyCode != spaceKeyCode && keyCode != escapeKeyCode {
        return Unmanaged.passUnretained(event)
    }

    // Filter auto-repeat so holding Space does not flap the toggle.
    if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
        return Unmanaged.passUnretained(event)
    }

    // Any modifier (Cmd, Ctrl, Opt, Fn) — let the OS handle Cmd+Space etc.
    if !event.flags.intersection(modifierMask).isEmpty {
        return Unmanaged.passUnretained(event)
    }

    let snapshot = ctx.snapshotHolder.current
    if !snapshot.spaceTriggerEnabled {
        return Unmanaged.passUnretained(event)
    }
    if snapshot.finderPid == 0 {
        return Unmanaged.passUnretained(event)
    }

    // Only act when Finder is the event target, i.e. the frontmost key app.
    let targetPid = event.getIntegerValueField(.eventTargetUnixProcessID)
    if targetPid != Int64(snapshot.finderPid) {
        return Unmanaged.passUnretained(event)
    }

    if snapshot.isFinderEditingText {
        return Unmanaged.passUnretained(event)
    }

    if keyCode == spaceKeyCode {
        // Fail-open: pass through unless the selection is a markdown file.
        guard case .markdown = snapshot.state else {
            return Unmanaged.passUnretained(event)
        }
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                ctx.onSpacePressed()
            }
        }
        return nil
    }

    if keyCode == escapeKeyCode {
        // Only swallow Esc when the preview is visible; otherwise Esc may
        // be needed by Finder for other purposes and we must not steal it.
        guard ctx.previewVisible.current else {
            return Unmanaged.passUnretained(event)
        }
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                ctx.onEscapePressed()
            }
        }
        return nil
    }

    return Unmanaged.passUnretained(event)
}
