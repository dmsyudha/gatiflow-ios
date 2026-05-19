import Foundation

public final class WatchdogMonitorException: NSException {
    public init(_ message: String) {
        super.init(name: NSExceptionName("WatchdogMonitorException"), reason: message, userInfo: nil)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}

final class WatchdogMonitor {
    private let timeoutMs: TimeInterval
    private let onHangDetected: (WatchdogMonitorException) -> Void
    private var ticker: Date = Date()
    private var watchdog: DispatchWorkItem?
    private var isRunning = false
    private let lock = NSLock()

    // Injectable for tests: the block that schedules the heartbeat on main
    let scheduleHeartbeat: (@escaping () -> Void, TimeInterval) -> Void

    init(
        timeoutMs: TimeInterval = 5_000,
        onHangDetected: @escaping (WatchdogMonitorException) -> Void,
        scheduleHeartbeat: ((@escaping () -> Void, TimeInterval) -> Void)? = nil
    ) {
        self.timeoutMs = timeoutMs
        self.onHangDetected = onHangDetected
        if let scheduleHeartbeat = scheduleHeartbeat {
            self.scheduleHeartbeat = scheduleHeartbeat
        } else {
            self.scheduleHeartbeat = { block, interval in
                DispatchQueue.main.asyncAfter(deadline: .now() + interval / 1000, execute: block)
            }
        }
    }

    func start() {
        lock.lock(); defer { lock.unlock() }
        guard !isRunning else { return }
        isRunning = true
        ticker = Date()
        scheduleHeartbeatPing()
        startWatchdogLoop()
    }

    func stop() {
        lock.lock(); defer { lock.unlock() }
        guard isRunning else { return }
        isRunning = false
        watchdog?.cancel()
        watchdog = nil
    }

    private func scheduleHeartbeatPing() {
        guard isRunning else { return }
        scheduleHeartbeat({ [weak self] in
            self?.tick()
        }, timeoutMs / 2)
    }

    private func tick() {
        lock.lock()
        ticker = Date()
        lock.unlock()
        scheduleHeartbeatPing()
    }

    private func startWatchdogLoop() {
        let item = DispatchWorkItem { [weak self] in
            self?.watchLoop()
        }
        watchdog = item
        DispatchQueue.global(qos: .utility).asyncAfter(
            deadline: .now() + timeoutMs / 1000,
            execute: item
        )
    }

    private func watchLoop() {
        lock.lock()
        guard isRunning else { lock.unlock(); return }
        let elapsed = Date().timeIntervalSince(ticker) * 1000
        lock.unlock()

        if elapsed >= timeoutMs {
            let ex = WatchdogMonitorException(
                "Main thread hang detected — blocked for >\(Int(timeoutMs))ms"
            )
            onHangDetected(ex)
            // reset ticker so it doesn't fire repeatedly for the same hang
            lock.lock(); ticker = Date(); lock.unlock()
        }

        // reschedule
        lock.lock()
        guard isRunning else { lock.unlock(); return }
        lock.unlock()
        startWatchdogLoop()
    }
}
