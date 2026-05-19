import Foundation

public protocol StorageManagerProtocol {
    func enqueueCrash(_ json: String)
    func dequeueCrashes(maxCount: Int) -> [String]
    func pendingCrashCount() -> Int
    func saveCurrentSessionId(_ id: String)
    func clearSessionId()
    func saveUserId(_ id: String?)
    func getUserId() -> String?
    func getDeviceId() -> String?
    func saveDeviceId(_ id: String)
}

final class StorageManager: StorageManagerProtocol {
    private let defaults: UserDefaults
    private let lock = NSLock()

    private enum Keys {
        static let crashQueue = "mhub_crash_queue"
        static let sessionId  = "mhub_session_id"
        static let userId     = "mhub_user_id"
        static let deviceId   = "mhub_device_id"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func enqueueCrash(_ json: String) {
        lock.lock(); defer { lock.unlock() }
        var queue = readQueue()
        queue.append(json)
        writeQueue(queue)
    }

    func dequeueCrashes(maxCount: Int) -> [String] {
        lock.lock(); defer { lock.unlock() }
        var queue = readQueue()
        let count = min(maxCount, queue.count)
        let batch = Array(queue.prefix(count))
        queue.removeFirst(count)
        writeQueue(queue)
        return batch
    }

    func pendingCrashCount() -> Int {
        lock.lock(); defer { lock.unlock() }
        return readQueue().count
    }

    func saveCurrentSessionId(_ id: String) {
        defaults.set(id, forKey: Keys.sessionId)
    }

    func clearSessionId() {
        defaults.removeObject(forKey: Keys.sessionId)
    }

    func saveUserId(_ id: String?) {
        if let id = id {
            defaults.set(id, forKey: Keys.userId)
        } else {
            defaults.removeObject(forKey: Keys.userId)
        }
    }

    func getUserId() -> String? {
        defaults.string(forKey: Keys.userId)
    }

    func getDeviceId() -> String? {
        defaults.string(forKey: Keys.deviceId)
    }

    func saveDeviceId(_ id: String) {
        defaults.set(id, forKey: Keys.deviceId)
    }

    private func readQueue() -> [String] {
        guard let data = defaults.string(forKey: Keys.crashQueue),
              let arr = try? JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String]
        else { return [] }
        return arr
    }

    private func writeQueue(_ queue: [String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: queue),
              let str = String(data: data, encoding: .utf8)
        else { return }
        defaults.set(str, forKey: Keys.crashQueue)
    }
}
