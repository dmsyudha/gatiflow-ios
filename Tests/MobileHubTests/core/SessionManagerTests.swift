import XCTest
@testable import MobileHub

final class SessionManagerTests: XCTestCase {

    private var storage: FakeStorage!
    private var deviceInfo: FakeDeviceInfo!
    private var sessionStartEvents: [String] = []
    private var sessionEndEvents: [String] = []
    private var manager: SessionManager!

    override func setUp() {
        super.setUp()
        storage = FakeStorage()
        deviceInfo = FakeDeviceInfo()
        sessionStartEvents = []
        sessionEndEvents = []
        manager = SessionManager(
            deviceInfo: deviceInfo,
            storage: storage,
            onSessionStart: { [weak self] id in self?.sessionStartEvents.append(id) },
            onSessionEnd: { [weak self] id in self?.sessionEndEvents.append(id) }
        )
    }

    // MARK: - register

    func test_registerFiresOnSessionStart() {
        manager.register()
        XCTAssertEqual(sessionStartEvents.count, 1)
    }

    func test_registerSavesSessionIdToStorage() {
        manager.register()
        XCTAssertNotNil(storage.savedSessionId)
    }

    // MARK: - Session ID

    func test_currentSessionIdNonEmptyAfterRegister() {
        manager.register()
        XCTAssertFalse(manager.currentSessionId.isEmpty)
    }

    func test_sessionIdIsUuidFormat() {
        manager.register()
        XCTAssertNotNil(UUID(uuidString: manager.currentSessionId))
    }

    // MARK: - buildSessionPayload

    func test_buildSessionPayloadContainsSessionId() {
        manager.register()
        let payload = manager.buildSessionPayload()
        XCTAssertEqual(payload.sessionId, manager.currentSessionId)
    }

    func test_buildSessionPayloadReflectsUserId() {
        storage.saveUserId("user-99")
        manager.register()
        let payload = manager.buildSessionPayload()
        XCTAssertEqual(payload.userId, "user-99")
    }

    func test_buildSessionPayloadNullUserIdWhenNotSet() {
        manager.register()
        let payload = manager.buildSessionPayload()
        XCTAssertNil(payload.userId)
    }

    func test_buildSessionPayloadDeviceFields() {
        manager.register()
        let payload = manager.buildSessionPayload()
        XCTAssertEqual(payload.deviceId, "test-device-1")
        XCTAssertEqual(payload.appVersion, "1.0")
        XCTAssertEqual(payload.osVersion, "iOS 18.0.0")
        XCTAssertEqual(payload.deviceModel, "iPhone 16")
        XCTAssertEqual(payload.country, "US")
    }
}
