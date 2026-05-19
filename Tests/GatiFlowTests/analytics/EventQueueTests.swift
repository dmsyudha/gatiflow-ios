import XCTest
@testable import GatiFlow

final class EventQueueTests: XCTestCase {

    private var http: FakeHttpClient!
    private var storage: FakeStorage!
    private var deviceInfo: FakeDeviceInfo!
    private var sessionManager: SessionManager!

    override func setUp() {
        super.setUp()
        http = FakeHttpClient()
        storage = FakeStorage()
        deviceInfo = FakeDeviceInfo()
        sessionManager = SessionManager(
            deviceInfo: deviceInfo,
            storage: storage,
            onSessionStart: { _ in },
            onSessionEnd: { _ in }
        )
        sessionManager.register()
    }

    private func makeQueue(maxBatchSize: Int = 10, flushIntervalMs: TimeInterval = 60_000) -> EventQueue {
        EventQueue(
            http: http,
            sessionManager: sessionManager,
            maxBatchSize: maxBatchSize,
            flushIntervalMs: flushIntervalMs
        )
    }

    // MARK: - Basic enqueue / flush

    func test_flushWithEmptyBufferDoesNothing() {
        let queue = makeQueue()
        queue.flush()
        XCTAssertEqual(http.callCount, 0)
    }

    func test_enqueuedEventsAreSentOnFlush() {
        let queue = makeQueue()
        queue.enqueue(EventPayload(name: "app_open"))
        queue.enqueue(EventPayload(name: "screen_view"))
        queue.flush()
        XCTAssertEqual(http.callCount, 1)
        XCTAssertEqual(http.lastPath, "/api/sdk/events")
    }

    func test_flushSendsAllEventsInSingleCall() throws {
        let queue = makeQueue()
        for i in 1...5 { queue.enqueue(EventPayload(name: "event_\(i)")) }
        queue.flush()
        let body = http.lastBody!
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [Any]
        XCTAssertEqual(arr.count, 5)
    }

    func test_bufferClearedAfterSuccessfulFlush() {
        let queue = makeQueue()
        queue.enqueue(EventPayload(name: "e1"))
        queue.flush()
        queue.flush() // second flush — buffer should be empty
        XCTAssertEqual(http.callCount, 1)
    }

    // MARK: - Auto-flush on batch size

    func test_autoFlushWhenBatchSizeReached() {
        let queue = makeQueue(maxBatchSize: 3)
        queue.enqueue(EventPayload(name: "e1"))
        queue.enqueue(EventPayload(name: "e2"))
        queue.enqueue(EventPayload(name: "e3")) // triggers auto-flush
        XCTAssertEqual(http.callCount, 1)
    }

    func test_noAutoFlushBeforeBatchSize() {
        let queue = makeQueue(maxBatchSize: 5)
        queue.enqueue(EventPayload(name: "e1"))
        queue.enqueue(EventPayload(name: "e2"))
        XCTAssertEqual(http.callCount, 0)
    }

    // MARK: - Failure and re-queuing

    func test_eventsReQueuedAtFrontOnFailure() throws {
        let queue = makeQueue()
        queue.enqueue(EventPayload(name: "critical_event"))
        http.shouldFail = true
        queue.flush()

        // Now succeed
        http.shouldFail = false
        queue.flush()
        let body = http.calls.last!.body
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [Any]
        XCTAssertGreaterThanOrEqual(arr.count, 1)
    }

    // MARK: - Stop

    func test_stopFlushesRemainingEvents() {
        let queue = makeQueue()
        queue.enqueue(EventPayload(name: "final_event"))
        queue.stop()
        XCTAssertEqual(http.callCount, 1)
    }

    // MARK: - Timed auto-flush

    func test_timedFlushFiresAfterInterval() {
        let exp = expectation(description: "timed flush")
        http.onPost = { exp.fulfill() }
        let queue = makeQueue(flushIntervalMs: 100)
        queue.enqueue(EventPayload(name: "timed_event"))
        queue.start()
        wait(for: [exp], timeout: 3)
        queue.stop()
    }

    // MARK: - Thread safety

    func test_concurrentEnqueueDoesNotLoseEvents() throws {
        let queue = makeQueue(maxBatchSize: 1000)
        let group = DispatchGroup()
        for i in 1...20 {
            group.enter()
            DispatchQueue.global().async {
                for j in 1...5 { queue.enqueue(EventPayload(name: "event_\(i)_\(j)")) }
                group.leave()
            }
        }
        group.wait()
        queue.flush()

        let body = http.lastBody!
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [Any]
        XCTAssertEqual(arr.count, 100, "All 100 events should be flushed")
    }
}
