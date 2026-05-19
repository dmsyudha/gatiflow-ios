import Foundation
@testable import MobileHub

final class FakeStorage: StorageManagerProtocol {
    private var queue: [String] = []
    private var sessionId: String?
    private var userId: String?
    private var deviceId: String?
    private let lock = NSLock()

    func enqueueCrash(_ json: String) {
        lock.lock(); defer { lock.unlock() }
        queue.append(json)
    }

    func dequeueCrashes(maxCount: Int) -> [String] {
        lock.lock(); defer { lock.unlock() }
        let count = min(maxCount, queue.count)
        let batch = Array(queue.prefix(count))
        queue.removeFirst(count)
        return batch
    }

    func pendingCrashCount() -> Int {
        lock.lock(); defer { lock.unlock() }
        return queue.count
    }

    func saveCurrentSessionId(_ id: String) { sessionId = id }
    func clearSessionId() { sessionId = nil }
    func saveUserId(_ id: String?) { userId = id }
    func getUserId() -> String? { userId }
    func getDeviceId() -> String? { deviceId }
    func saveDeviceId(_ id: String) { deviceId = id }

    // Inspection helpers
    var savedSessionId: String? { sessionId }
    var crashQueueSnapshot: [String] { lock.lock(); defer { lock.unlock() }; return queue }
}
