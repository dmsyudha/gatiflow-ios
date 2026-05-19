import XCTest
@testable import MobileHub

final class ConfigTests: XCTestCase {

    // MARK: - Defaults

    func test_defaultBaseUrl() {
        let c = Config.Builder(appToken: "tok").build()
        XCTAssertEqual(c.baseUrl, "https://mobilehub.app")
    }

    func test_defaultMaxCrashQueueSize() {
        let c = Config.Builder(appToken: "tok").build()
        XCTAssertEqual(c.maxCrashQueueSize, 50)
    }

    func test_defaultMaxEventBatchSize() {
        let c = Config.Builder(appToken: "tok").build()
        XCTAssertEqual(c.maxEventBatchSize, 20)
    }

    func test_defaultFlushInterval() {
        let c = Config.Builder(appToken: "tok").build()
        XCTAssertEqual(c.flushIntervalMs, 30_000)
    }

    func test_defaultDebugLoggingOff() {
        let c = Config.Builder(appToken: "tok").build()
        XCTAssertFalse(c.debugLogging)
    }

    func test_defaultWatchdogTimeout() {
        let c = Config.Builder(appToken: "tok").build()
        XCTAssertEqual(c.watchdogTimeoutMs, 5_000)
    }

    // MARK: - Custom values

    func test_customBaseUrlTrimmed() {
        let c = Config.Builder(appToken: "tok").baseUrl("https://example.com///").build()
        XCTAssertEqual(c.baseUrl, "https://example.com")
    }

    func test_customMaxCrashQueueSize() {
        let c = Config.Builder(appToken: "tok").maxCrashQueueSize(10).build()
        XCTAssertEqual(c.maxCrashQueueSize, 10)
    }

    func test_customMaxEventBatchSize() {
        let c = Config.Builder(appToken: "tok").maxEventBatchSize(5).build()
        XCTAssertEqual(c.maxEventBatchSize, 5)
    }

    func test_customFlushInterval() {
        let c = Config.Builder(appToken: "tok").flushIntervalMs(1_000).build()
        XCTAssertEqual(c.flushIntervalMs, 1_000)
    }

    func test_debugLoggingEnabled() {
        let c = Config.Builder(appToken: "tok").debugLogging(true).build()
        XCTAssertTrue(c.debugLogging)
    }

    func test_customWatchdogTimeout() {
        let c = Config.Builder(appToken: "tok").watchdogTimeoutMs(3_000).build()
        XCTAssertEqual(c.watchdogTimeoutMs, 3_000)
    }

    // MARK: - Fluency

    func test_builderReturnsSelf() {
        let builder = Config.Builder(appToken: "tok")
        let result = builder.debugLogging(true)
        XCTAssertTrue(result === builder)
    }

    func test_independentBuilds() {
        let builder = Config.Builder(appToken: "tok")
        _ = builder.maxCrashQueueSize(5)
        let c1 = builder.build()
        _ = builder.maxCrashQueueSize(99)
        let c2 = builder.build()
        XCTAssertEqual(c1.maxCrashQueueSize, 5)
        XCTAssertEqual(c2.maxCrashQueueSize, 99)
    }

    func test_appTokenIsStored() {
        let c = Config.Builder(appToken: "my-secret-token").build()
        XCTAssertEqual(c.appToken, "my-secret-token")
    }
}
