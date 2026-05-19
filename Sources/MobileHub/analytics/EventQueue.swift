import Foundation

final class EventQueue {
    private let http: HttpClientProtocol
    private let sessionManager: SessionManager
    private let maxBatchSize: Int
    private let flushIntervalMs: TimeInterval

    private var buffer: [EventPayload] = []
    private let lock = NSLock()
    private var timer: Timer?

    init(
        http: HttpClientProtocol,
        sessionManager: SessionManager,
        maxBatchSize: Int = 20,
        flushIntervalMs: TimeInterval = 30_000
    ) {
        self.http = http
        self.sessionManager = sessionManager
        self.maxBatchSize = maxBatchSize
        self.flushIntervalMs = flushIntervalMs
    }

    func start() {
        let interval = flushIntervalMs / 1000
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.flush()
            }
        }
    }

    func enqueue(_ event: EventPayload) {
        lock.lock()
        buffer.append(event)
        let shouldFlush = buffer.count >= maxBatchSize
        lock.unlock()
        if shouldFlush { flush() }
    }

    func flush() {
        lock.lock()
        guard !buffer.isEmpty else { lock.unlock(); return }
        let batch = buffer
        buffer.removeAll()
        lock.unlock()

        let body = EventSerializer.toRequestBody(events: batch, session: sessionManager.buildSessionPayload())
        http.postJson(path: "/api/sdk/events", body: body, onSuccess: {}) { [weak self] _ in
            guard let self else { return }
            self.lock.lock()
            self.buffer.insert(contentsOf: batch, at: 0)
            self.lock.unlock()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        flush()
    }
}
