import XCTest
@testable import GatiFlow

final class CrashPayloadTests: XCTestCase {

    private let device = FakeDeviceInfo()

    // MARK: - from(error:)

    func test_exceptionClassFromError() {
        let error = TestError.sample
        let payload = CrashPayload.from(
            error: error, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: nil, metadata: [:]
        )
        XCTAssertTrue(payload.exceptionClass.contains("TestError"))
    }

    func test_messageTruncatedTo200Chars() {
        let longMessage = String(repeating: "a", count: 300)
        let error = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: longMessage])
        let payload = CrashPayload.from(
            error: error, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: nil, metadata: [:]
        )
        XCTAssertLessThanOrEqual(payload.message.count, 200)
    }

    func test_metadataPassedThrough() {
        let error = TestError.sample
        let payload = CrashPayload.from(
            error: error, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: "u1",
            metadata: ["screen": "Home", "build": "42"]
        )
        XCTAssertEqual(payload.metadata["screen"], "Home")
        XCTAssertEqual(payload.metadata["build"], "42")
    }

    func test_userIdPassedThrough() {
        let payload = CrashPayload.from(
            error: TestError.sample, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: "user-xyz", metadata: [:]
        )
        XCTAssertEqual(payload.userId, "user-xyz")
    }

    // MARK: - from(exception:)

    func test_exceptionClassFromNSException() {
        let ex = NSException(name: NSExceptionName("MyException"), reason: "reason", userInfo: nil)
        let payload = CrashPayload.from(
            exception: ex, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: nil, metadata: [:]
        )
        XCTAssertEqual(payload.exceptionClass, "MyException")
    }

    func test_exceptionReasonUsedAsMessage() {
        let ex = NSException(name: NSExceptionName("Test"), reason: "null pointer", userInfo: nil)
        let payload = CrashPayload.from(
            exception: ex, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: nil, metadata: [:]
        )
        XCTAssertEqual(payload.message, "null pointer")
    }

    func test_nilReasonFallsBackToDefault() {
        let ex = NSException(name: NSExceptionName("Test"), reason: nil, userInfo: nil)
        let payload = CrashPayload.from(
            exception: ex, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: nil, metadata: [:]
        )
        XCTAssertFalse(payload.message.isEmpty)
    }

    // MARK: - JSON round-trip

    func test_toJsonContainsCrashKey() {
        let payload = makeSamplePayload()
        let json = payload.toJson()
        let root = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        XCTAssertNotNil(root?["crash"])
    }

    func test_jsonRoundTrip() {
        let payload = makeSamplePayload()
        let json = payload.toJson()
        let restored = CrashPayload.fromJson(json)
        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.exceptionClass, payload.exceptionClass)
        XCTAssertEqual(restored?.message, payload.message)
        XCTAssertEqual(restored?.appVersion, payload.appVersion)
        XCTAssertEqual(restored?.deviceId, payload.deviceId)
    }

    func test_nullUserIdOmittedFromJson() {
        let payload = makeSamplePayload(userId: nil)
        let json = payload.toJson()
        let root = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        let crash = root?["crash"] as? [String: Any]
        XCTAssertNil(crash?["userId"])
    }

    func test_userIdPresentInJson() {
        let payload = makeSamplePayload(userId: "user-1")
        let json = payload.toJson()
        let root = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        let crash = root?["crash"] as? [String: Any]
        XCTAssertEqual(crash?["userId"] as? String, "user-1")
    }

    func test_fromJsonReturnsNilForGarbage() {
        XCTAssertNil(CrashPayload.fromJson("not json at all"))
    }

    func test_unicodeMessagePreserved() {
        let error = NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "日本語エラー"])
        let payload = CrashPayload.from(
            error: error, appVersion: "1.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone", userId: nil, metadata: [:]
        )
        XCTAssertTrue(payload.message.contains("日本語"))
    }

    // MARK: - Helpers

    private func makeSamplePayload(userId: String? = "u1") -> CrashPayload {
        CrashPayload.from(
            error: TestError.sample,
            appVersion: "2.0", osVersion: "iOS 18",
            deviceId: "d1", deviceModel: "iPhone",
            userId: userId, metadata: ["key": "val"]
        )
    }
}

private enum TestError: Error {
    case sample
}
