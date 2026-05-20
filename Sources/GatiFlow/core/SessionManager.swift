import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class SessionManager {
    public private(set) var currentSessionId: String = ""

    private let deviceInfo: DeviceInfoProtocol
    private let storage: StorageManagerProtocol
    private let onSessionStart: (String) -> Void
    private let onSessionEnd: (String) -> Void

    private var activeCount = 0
    private let lock = NSLock()
    private var observers: [NSObjectProtocol] = []

    init(
        deviceInfo: DeviceInfoProtocol,
        storage: StorageManagerProtocol,
        onSessionStart: @escaping (String) -> Void,
        onSessionEnd: @escaping (String) -> Void
    ) {
        self.deviceInfo = deviceInfo
        self.storage = storage
        self.onSessionStart = onSessionStart
        self.onSessionEnd = onSessionEnd
    }

    public func register() {
        startNewSession()
        attachLifecycleObservers()
    }

    public func unregister() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    public func buildSessionPayload() -> SessionPayload {
        SessionPayload(
            sessionId: currentSessionId,
            userId: storage.getUserId(),
            deviceId: deviceInfo.deviceId,
            appVersion: deviceInfo.appVersion,
            osVersion: deviceInfo.osVersion,
            deviceModel: deviceInfo.deviceModel,
            country: deviceInfo.country
        )
    }

    private func attachLifecycleObservers() {
        #if canImport(UIKit)
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.appDidBecomeActive() })
        observers.append(center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.appDidEnterBackground() })
        #endif
    }

    private func appDidBecomeActive() {
        lock.lock(); defer { lock.unlock() }
        activeCount += 1
        if activeCount == 1 {
            startNewSession()
        }
    }

    private func appDidEnterBackground() {
        lock.lock(); defer { lock.unlock() }
        activeCount -= 1
        if activeCount <= 0 {
            activeCount = 0
            let endedId = currentSessionId
            storage.clearSessionId()
            onSessionEnd(endedId)
        }
    }

    private func startNewSession() {
        currentSessionId = UUID().uuidString
        storage.saveCurrentSessionId(currentSessionId)
        onSessionStart(currentSessionId)
    }
}
