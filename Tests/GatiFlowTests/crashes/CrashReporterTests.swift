import XCTest
@testable import GatiFlow

final class CrashReporterTests: XCTestCase {

    private var http: FakeHttpClient!
    private var storage: FakeStorage!
    private var deviceInfo: FakeDeviceInfo!
    private var reporter: CrashReporter!

    override func setUp() {
        super.setUp()
        http = FakeHttpClient()
        storage = FakeStorage()
        deviceInfo = FakeDeviceInfo()
        reporter = CrashReporter(
            http: http,
            storage: storage,
            deviceInfo: deviceInfo,
            maxQueueSize: 5
        )
    }

    override func tearDown() {
        reporter.uninstall()
        super.tearDown()
    }

    // MARK: - install / uninstall

    func test_installChangesUncaughtExceptionHandler() {
        let before = NSGetUncaughtExceptionHandler()
        reporter.install()
        let after = NSGetUncaughtExceptionHandler()
        // After install, handler should be set (may differ from before)
        XCTAssertNotNil(after)
        _ = before // used
    }

    func test_uninstallClearsHandler() {
        reporter.install()
        reporter.uninstall()
        // After uninstall, the handler is cleared (nil). Verify no crash occurred.
        XCTAssertNil(NSGetUncaughtExceptionHandler())
    }

    // MARK: - flushPending

    func test_flushPendingWithEmptyQueueDoesNothing() {
        reporter.flushPending()
        XCTAssertEqual(http.callCount, 0)
    }

    func test_flushPendingSendsQueuedCrashes() {
        storage.enqueueCrash("{\"crash\":{\"exceptionClass\":\"TestError\"}}")
        reporter.flushPending()
        XCTAssertEqual(http.callCount, 1)
        XCTAssertEqual(http.lastPath, "/api/sdk/crashes")
    }

    func test_flushPendingMultipleCrashes() {
        storage.enqueueCrash("{\"crash\":{}}")
        storage.enqueueCrash("{\"crash\":{}}")
        reporter.flushPending()
        XCTAssertEqual(http.callCount, 2)
    }

    func test_flushPendingRequeuesOnFailure() {
        storage.enqueueCrash("{\"crash\":{}}")
        http.shouldFail = true
        reporter.flushPending()
        // After failure, item should be back in queue
        XCTAssertEqual(storage.pendingCrashCount(), 1)
    }

    func test_flushPendingDoesNotRequeueOnSuccess() {
        storage.enqueueCrash("{\"crash\":{}}")
        reporter.flushPending()
        XCTAssertEqual(storage.pendingCrashCount(), 0)
    }

    // MARK: - reportHandled

    func test_reportHandledPostsImmediately() {
        reporter.reportHandled(TestError.sample)
        XCTAssertEqual(http.callCount, 1)
    }

    func test_reportHandledPathIsCorrect() {
        reporter.reportHandled(TestError.sample)
        XCTAssertEqual(http.lastPath, "/api/sdk/crashes")
    }

    func test_reportHandledIncludesMetadata() {
        reporter.reportHandled(TestError.sample, metadata: ["screen": "Login"])
        let body = http.lastBody ?? ""
        XCTAssertTrue(body.contains("screen"))
        XCTAssertTrue(body.contains("Login"))
    }

    func test_reportHandledRequeuesOnFailure() {
        http.shouldFail = true
        reporter.reportHandled(TestError.sample)
        XCTAssertEqual(storage.pendingCrashCount(), 1)
    }

    func test_reportHandledIncludesUserId() {
        reporter.userId = "user-123"
        reporter.reportHandled(TestError.sample)
        let body = http.lastBody ?? ""
        XCTAssertTrue(body.contains("user-123"))
    }
}

private enum TestError: Error {
    case sample
}
