import XCTest
@testable import GatiFlow

final class StorageManagerTests: XCTestCase {

    private var storage: StorageManager!

    override func setUp() {
        super.setUp()
        // Use a throwaway suite so tests don't bleed into production data
        let suiteName = "com.gatiflow.test.\(UUID().uuidString)"
        storage = StorageManager(defaults: UserDefaults(suiteName: suiteName)!)
    }

    // MARK: - Crash queue basics

    func test_enqueueAndDequeueRoundTrip() {
        storage.enqueueCrash("{\"crash\":\"a\"}")
        let result = storage.dequeueCrashes(maxCount: 10)
        XCTAssertEqual(result, ["{\"crash\":\"a\"}"])
    }

    func test_dequeueRespectsMaxCount() {
        for i in 1...5 { storage.enqueueCrash("crash\(i)") }
        let batch = storage.dequeueCrashes(maxCount: 3)
        XCTAssertEqual(batch.count, 3)
        XCTAssertEqual(storage.pendingCrashCount(), 2)
    }

    func test_dequeueFromEmptyReturnsEmpty() {
        XCTAssertEqual(storage.dequeueCrashes(maxCount: 5), [])
    }

    func test_fifoOrdering() {
        storage.enqueueCrash("first")
        storage.enqueueCrash("second")
        storage.enqueueCrash("third")
        let batch = storage.dequeueCrashes(maxCount: 3)
        XCTAssertEqual(batch, ["first", "second", "third"])
    }

    func test_pendingCrashCountAccurate() {
        XCTAssertEqual(storage.pendingCrashCount(), 0)
        storage.enqueueCrash("a")
        storage.enqueueCrash("b")
        XCTAssertEqual(storage.pendingCrashCount(), 2)
        _ = storage.dequeueCrashes(maxCount: 1)
        XCTAssertEqual(storage.pendingCrashCount(), 1)
    }

    func test_dequeueMoreThanAvailableReturnsAll() {
        storage.enqueueCrash("only")
        let batch = storage.dequeueCrashes(maxCount: 100)
        XCTAssertEqual(batch.count, 1)
    }

    // MARK: - Session ID

    func test_saveAndClearSessionId() {
        storage.saveCurrentSessionId("sess-abc")
        // Verify via save/clear cycle — no direct getter exposed
        storage.clearSessionId()
        // After clear, a fresh storage should not have it
        // We check indirectly via another enqueue (clearing didn't corrupt queue)
        storage.enqueueCrash("ok")
        XCTAssertEqual(storage.pendingCrashCount(), 1)
    }

    // MARK: - User ID

    func test_saveAndGetUserId() {
        storage.saveUserId("user-42")
        XCTAssertEqual(storage.getUserId(), "user-42")
    }

    func test_clearUserIdWithNil() {
        storage.saveUserId("user-42")
        storage.saveUserId(nil)
        XCTAssertNil(storage.getUserId())
    }

    func test_getUserIdReturnsNilWhenNotSet() {
        XCTAssertNil(storage.getUserId())
    }

    // MARK: - Device ID

    func test_saveAndGetDeviceId() {
        storage.saveDeviceId("dev-123")
        XCTAssertEqual(storage.getDeviceId(), "dev-123")
    }

    func test_getDeviceIdReturnsNilWhenNotSet() {
        XCTAssertNil(storage.getDeviceId())
    }

    // MARK: - Thread safety

    func test_concurrentEnqueueDoesNotLoseItems() {
        let expectation = self.expectation(description: "all threads complete")
        expectation.expectedFulfillmentCount = 10
        for _ in 0..<10 {
            DispatchQueue.global().async {
                for _ in 0..<5 { self.storage.enqueueCrash("payload") }
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5)
        XCTAssertEqual(storage.pendingCrashCount(), 50)
    }
}
