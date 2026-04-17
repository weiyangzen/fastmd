import AppKit

@MainActor
final class HoverMonitorService {
    var onHoverPause: ((NSPoint) -> Void)?
    var onHoverWarmup: ((NSPoint) -> Void)?
    var onMouseActivity: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var hoverWarmupWorkItem: DispatchWorkItem?
    private var hoverWorkItem: DispatchWorkItem?
    private var lastHandledEventTimestamp: TimeInterval = 0
    private var lastHandledEventType: NSEvent.EventType?
    private let hoverDelay: TimeInterval
    private let hoverWarmupDelay: TimeInterval

    init(hoverDelay: TimeInterval = 1.0, hoverWarmupDelay: TimeInterval = 0.7) {
        self.hoverDelay = hoverDelay
        self.hoverWarmupDelay = min(max(0.0, hoverWarmupDelay), hoverDelay)
    }

    func start() {
        stop()

        let pointerMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: pointerMask) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseActivity(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: pointerMask) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseActivity(event)
            }
            return event
        }
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            Task { @MainActor in
                self?.handleScrollActivity(event)
            }
        }
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            Task { @MainActor in
                self?.handleScrollActivity(event)
            }
            return event
        }

        handleMouseActivity(nil)
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalScrollMonitor {
            NSEvent.removeMonitor(globalScrollMonitor)
            self.globalScrollMonitor = nil
        }
        if let localScrollMonitor {
            NSEvent.removeMonitor(localScrollMonitor)
            self.localScrollMonitor = nil
        }
        hoverWarmupWorkItem?.cancel()
        hoverWarmupWorkItem = nil
        hoverWorkItem?.cancel()
        hoverWorkItem = nil
        lastHandledEventTimestamp = 0
        lastHandledEventType = nil
    }

    func noteExternalScrollActivity() {
        handleScrollActivity(nil)
    }

    private func handleMouseActivity(_ event: NSEvent?) {
        registerActivity(event)
    }

    private func handleScrollActivity(_ event: NSEvent?) {
        registerActivity(event)
    }

    private func registerActivity(_ event: NSEvent?) {
        if let event, isDuplicate(event: event) {
            return
        }
        onMouseActivity?()
        hoverWarmupWorkItem?.cancel()
        hoverWorkItem?.cancel()
        scheduleHoverTimers()
    }

    private func scheduleHoverTimers() {
        let warmupWork = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.onHoverWarmup?(NSEvent.mouseLocation)
        }
        hoverWarmupWorkItem = warmupWork
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverWarmupDelay, execute: warmupWork)

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.onHoverPause?(NSEvent.mouseLocation)
        }
        hoverWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverDelay, execute: work)
    }

    private func isDuplicate(event: NSEvent) -> Bool {
        let isSameType = lastHandledEventType == event.type
        let isSameTimestamp = abs(lastHandledEventTimestamp - event.timestamp) < 0.0001
        lastHandledEventTimestamp = event.timestamp
        lastHandledEventType = event.type
        return isSameType && isSameTimestamp
    }
}
