import Foundation

public final class Crashes: MobileHubService {
    var reporter: CrashReporter?
    var watchdog: WatchdogMonitor?
    private var enabled = true

    var http: HttpClientProtocol?
    var storage: StorageManagerProtocol?
    var deviceInfo: DeviceInfoProtocol?
    var watchdogTimeoutMs: TimeInterval = 5_000

    override public func onStart() {
        guard enabled, let http, let storage, let deviceInfo else { return }
        let r = CrashReporter(http: http, storage: storage, deviceInfo: deviceInfo)
        reporter = r
        r.install()
        r.flushPending()

        let w = WatchdogMonitor(timeoutMs: watchdogTimeoutMs) { [weak r] ex in
            r?.reportHandled(CrashesError.watchdog(ex.reason ?? "hang"), metadata: [:])
        }
        watchdog = w
        w.start()
    }

    override public func onStop() {
        watchdog?.stop()
        reporter?.uninstall()
    }

    public func trackError(_ error: Error, metadata: [String: String] = [:]) {
        guard enabled else { return }
        reporter?.reportHandled(error, metadata: metadata)
    }

    public func setEnabled(_ value: Bool) {
        enabled = value
    }

    public func setUserId(_ id: String?) {
        reporter?.userId = id
    }
}

enum CrashesError: Error {
    case watchdog(String?)
}
