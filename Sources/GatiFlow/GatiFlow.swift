import Foundation

public final class GatiFlow {
    public static let shared = GatiFlow()
    private init() {}

    private var config: Config?
    private var storage: StorageManagerProtocol?
    private var deviceInfo: DeviceInfoProtocol?
    private var http: HttpClientProtocol?
    private var sessionManager: SessionManager?
    private var registry: ServiceRegistry?

    public var crashes: Crashes? { registry?.get(Crashes.self) }
    public var analytics: Analytics? { registry?.get(Analytics.self) }

    // MARK: - Start

    public func start(appToken: String, services: [GatiFlowService] = []) {
        let config = Config.Builder(appToken: appToken).build()
        start(config: config, services: services)
    }

    public func start(config: Config, services: [GatiFlowService] = []) {
        self.config = config
        Logger.debugEnabled = config.debugLogging

        let store = StorageManager()
        let info = DeviceInfo(storage: store)
        let client = HttpClient(baseUrl: config.baseUrl, appToken: config.appToken)

        self.storage = store
        self.deviceInfo = info
        self.http = client

        let sm = SessionManager(
            deviceInfo: info,
            storage: store,
            onSessionStart: { [weak self] id in
                Logger.d("SessionManager", "Session started: \(id)")
                self?.analytics?.flush()
            },
            onSessionEnd: { [weak self] id in
                Logger.d("SessionManager", "Session ended: \(id)")
                self?.analytics?.flush()
            }
        )
        self.sessionManager = sm

        let reg = ServiceRegistry()
        for service in services {
            if let c = service as? Crashes {
                c.http = client
                c.storage = store
                c.deviceInfo = info
                c.watchdogTimeoutMs = config.watchdogTimeoutMs
            }
            if let a = service as? Analytics {
                a.http = client
                a.sessionManager = sm
                a.maxBatchSize = config.maxEventBatchSize
                a.flushIntervalMs = config.flushIntervalMs
            }
            reg.register(service)
        }
        self.registry = reg

        sm.register()
        reg.start()
    }

    // MARK: - Identity

    public func setUserId(_ id: String?) {
        storage?.saveUserId(id)
        crashes?.setUserId(id)
    }

    // MARK: - Stop

    public func stop() {
        registry?.stop()
        sessionManager?.unregister()
        config = nil
    }
}
