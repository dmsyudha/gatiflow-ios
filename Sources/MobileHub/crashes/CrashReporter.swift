import Foundation

// Stored outside the class so a @convention(c) closure can capture it
private var _previousExceptionHandler: NSUncaughtExceptionHandler?
private weak var _activeCrashReporter: CrashReporter?

final class CrashReporter {
    private let http: HttpClientProtocol
    private let storage: StorageManagerProtocol
    private let deviceInfo: DeviceInfoProtocol
    private let maxQueueSize: Int
    var userId: String?

    init(
        http: HttpClientProtocol,
        storage: StorageManagerProtocol,
        deviceInfo: DeviceInfoProtocol,
        maxQueueSize: Int = 50
    ) {
        self.http = http
        self.storage = storage
        self.deviceInfo = deviceInfo
        self.maxQueueSize = maxQueueSize
    }

    func install() {
        _previousExceptionHandler = NSGetUncaughtExceptionHandler()
        _activeCrashReporter = self
        NSSetUncaughtExceptionHandler { exception in
            _activeCrashReporter?.handleException(exception)
            _previousExceptionHandler?(exception)
        }
        installSignalHandlers()
    }

    func uninstall() {
        _activeCrashReporter = nil
        NSSetUncaughtExceptionHandler(nil)
    }

    func flushPending() {
        let crashes = storage.dequeueCrashes(maxCount: 10)
        guard !crashes.isEmpty else { return }
        for json in crashes {
            http.postJson(path: "/api/sdk/crashes", body: json, onSuccess: {}) { [weak self] _ in
                self?.storage.enqueueCrash(json)
            }
        }
    }

    func reportHandled(_ error: Error, metadata: [String: String] = [:]) {
        let payload = CrashPayload.from(
            error: error,
            appVersion: deviceInfo.appVersion,
            osVersion: deviceInfo.osVersion,
            deviceId: deviceInfo.deviceId,
            deviceModel: deviceInfo.deviceModel,
            userId: userId,
            metadata: metadata
        )
        let json = payload.toJson()
        http.postJson(path: "/api/sdk/crashes", body: json, onSuccess: {}) { [weak self] _ in
            self?.storage.enqueueCrash(json)
        }
    }

    private func handleException(_ exception: NSException) {
        let payload = CrashPayload.from(
            exception: exception,
            appVersion: deviceInfo.appVersion,
            osVersion: deviceInfo.osVersion,
            deviceId: deviceInfo.deviceId,
            deviceModel: deviceInfo.deviceModel,
            userId: userId,
            metadata: [:]
        )
        evictIfNeeded()
        storage.enqueueCrash(payload.toJson())
    }

    private func evictIfNeeded() {
        while storage.pendingCrashCount() >= maxQueueSize {
            _ = storage.dequeueCrashes(maxCount: 1)
        }
    }

    private func installSignalHandlers() {
        let handler: @convention(c) (Int32) -> Void = { sig in
            let ex = NSException(
                name: NSExceptionName("Signal \(sig)"),
                reason: "Fatal signal \(sig) received",
                userInfo: nil
            )
            NSGetUncaughtExceptionHandler()?(ex)
        }
        signal(SIGSEGV, handler)
        signal(SIGABRT, handler)
        signal(SIGBUS, handler)
        signal(SIGILL, handler)
        signal(SIGTRAP, handler)
        signal(SIGFPE, handler)
    }
}
