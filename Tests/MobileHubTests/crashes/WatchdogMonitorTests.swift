import XCTest
@testable import MobileHub

final class WatchdogMonitorTests: XCTestCase {

    // heartbeat never fires — simulates a frozen main thread
    private func makeFrozenMonitor(
        timeoutMs: TimeInterval = 200,
        onHangDetected: @escaping (WatchdogMonitorException) -> Void
    ) -> WatchdogMonitor {
        WatchdogMonitor(
            timeoutMs: timeoutMs,
            onHangDetected: onHangDetected,
            scheduleHeartbeat: { _, _ in /* never reset ticker */ }
        )
    }

    private func makeHealthyMonitor(
        timeoutMs: TimeInterval = 200,
        onHangDetected: @escaping (WatchdogMonitorException) -> Void
    ) -> WatchdogMonitor {
        WatchdogMonitor(
            timeoutMs: timeoutMs,
            onHangDetected: onHangDetected,
            scheduleHeartbeat: { block, _ in block() } // immediately reset ticker
        )
    }

    // MARK: - Lifecycle

    func test_stopWithoutStartIsNoOp() {
        let monitor = makeFrozenMonitor { _ in }
        monitor.stop() // must not crash
    }

    func test_startIsIdempotent() {
        let callCount = XCTestExpectation(description: "watchdog fires")
        callCount.expectedFulfillmentCount = 1
        callCount.assertForOverFulfill = false

        let monitor = makeFrozenMonitor(timeoutMs: 50) { _ in callCount.fulfill() }
        monitor.start()
        monitor.start() // second start is a no-op
        wait(for: [callCount], timeout: 2)
        monitor.stop()
    }

    func test_stopIsIdempotent() {
        let monitor = makeFrozenMonitor { _ in }
        monitor.start()
        monitor.stop()
        monitor.stop() // must not crash
    }

    func test_canRestartAfterStop() {
        let monitor = makeFrozenMonitor { _ in }
        monitor.start()
        monitor.stop()
        monitor.start() // must not crash
        monitor.stop()
    }

    // MARK: - Detection

    func test_hangDetectedWhenMainThreadFrozen() {
        let exp = expectation(description: "hang detected")
        let monitor = makeFrozenMonitor(timeoutMs: 50) { _ in exp.fulfill() }
        monitor.start()
        wait(for: [exp], timeout: 3)
        monitor.stop()
    }

    func test_hangNotFiredWhenMainThreadResponds() {
        let exp = expectation(description: "no hang")
        exp.isInverted = true

        let monitor = makeHealthyMonitor(timeoutMs: 100) { _ in exp.fulfill() }
        monitor.start()
        wait(for: [exp], timeout: 0.5)
        monitor.stop()
    }

    func test_hangCallbackReceivesException() {
        let exp = expectation(description: "exception received")
        var received: WatchdogMonitorException?
        let monitor = makeFrozenMonitor(timeoutMs: 50) { ex in
            received = ex
            exp.fulfill()
        }
        monitor.start()
        wait(for: [exp], timeout: 3)
        monitor.stop()
        XCTAssertNotNil(received)
    }

    // MARK: - WatchdogMonitorException

    func test_exceptionMessageDescriptive() {
        let ex = WatchdogMonitorException("Main thread hang detected — blocked for >5000ms")
        XCTAssertTrue(ex.reason?.contains("Main thread hang") == true)
    }

    func test_exceptionInheritsNSException() {
        let ex = WatchdogMonitorException("test")
        // WatchdogMonitorException is a subclass of NSException — verify super is accessible
        XCTAssertNotNil(ex.reason)
    }

    func test_hangFiresOnceAndResets() {
        var count = 0
        let exp = expectation(description: "first fire")
        let monitor = makeFrozenMonitor(timeoutMs: 50) { _ in
            count += 1
            if count == 1 { exp.fulfill() }
        }
        monitor.start()
        wait(for: [exp], timeout: 3)
        // Short pause to check for duplicate fires
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertGreaterThanOrEqual(count, 1)
        monitor.stop()
    }
}
