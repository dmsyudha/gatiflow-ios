import Foundation

public final class Analytics: GatiFlowService {
    private var queue: EventQueue?
    private var enabled = true

    var http: HttpClientProtocol?
    var sessionManager: SessionManager?
    var maxBatchSize: Int = 20
    var flushIntervalMs: TimeInterval = 30_000

    override public func onStart() {
        guard let http, let sessionManager else { return }
        let q = EventQueue(
            http: http,
            sessionManager: sessionManager,
            maxBatchSize: maxBatchSize,
            flushIntervalMs: flushIntervalMs
        )
        queue = q
        q.start()
    }

    override public func onStop() {
        queue?.stop()
        queue = nil
    }

    public func trackEvent(_ name: String, properties: [String: Any]? = nil) {
        guard enabled else { return }
        queue?.enqueue(EventPayload(name: name, properties: properties))
    }

    public func flush() {
        queue?.flush()
    }

    public func setEnabled(_ value: Bool) {
        enabled = value
    }
}
