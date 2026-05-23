import Foundation

public final class Config {
    public let appToken: String
    public let baseUrl: String
    public let maxCrashQueueSize: Int
    public let maxEventBatchSize: Int
    public let flushIntervalMs: TimeInterval
    public let debugLogging: Bool
    public let watchdogTimeoutMs: TimeInterval

    private init(builder: Builder) {
        self.appToken = builder.appToken
        self.baseUrl = builder.baseUrl
        self.maxCrashQueueSize = builder.maxCrashQueueSize
        self.maxEventBatchSize = builder.maxEventBatchSize
        self.flushIntervalMs = builder.flushIntervalMs
        self.debugLogging = builder.debugLogging
        self.watchdogTimeoutMs = builder.watchdogTimeoutMs
    }

    public final class Builder {

        // MARK: Stored properties

        let appToken: String
        var baseUrl: String = "https://app.gatiflow.dev"
        var maxCrashQueueSize: Int = 50
        var maxEventBatchSize: Int = 20
        var flushIntervalMs: TimeInterval = 30_000
        var debugLogging: Bool = false
        var watchdogTimeoutMs: TimeInterval = 5_000

        // MARK: Init

        public init(appToken: String) {
            precondition(!appToken.trimmingCharacters(in: .whitespaces).isEmpty, "appToken must not be blank")
            self.appToken = appToken
        }

        // MARK: Plist factory

        /// Creates a Builder by reading `GatiFlowAppToken` (and optionally
        /// `GatiFlowBaseUrl`) from the given bundle's Info.plist.
        /// Returns `nil` if the token key is absent or blank.
        ///
        /// ```swift
        /// if let builder = Config.Builder.fromPlist() {
        ///     let config = builder.debugLogging(true).build()
        ///     GatiFlow.shared.start(config: config, services: [Crashes(), Analytics()])
        /// }
        /// ```
        public static func fromPlist(bundle: Bundle = .main) -> Builder? {
            guard
                let dict  = bundle.infoDictionary,
                let token = dict["GatiFlowAppToken"] as? String,
                !token.trimmingCharacters(in: .whitespaces).isEmpty
            else { return nil }
            let builder = Builder(appToken: token)
            if let url = dict["GatiFlowBaseUrl"] as? String, !url.isEmpty {
                _ = builder.baseUrl(url)
            }
            return builder
        }

        // MARK: Chainable setters

        @discardableResult
        public func baseUrl(_ value: String) -> Builder {
            let trimmed = value.trimmingCharacters(in: .init(charactersIn: "/"))
            precondition(trimmed.hasPrefix("http"), "baseUrl must start with http")
            baseUrl = trimmed
            return self
        }

        @discardableResult
        public func maxCrashQueueSize(_ value: Int) -> Builder {
            maxCrashQueueSize = value
            return self
        }

        @discardableResult
        public func maxEventBatchSize(_ value: Int) -> Builder {
            maxEventBatchSize = value
            return self
        }

        @discardableResult
        public func flushIntervalMs(_ value: TimeInterval) -> Builder {
            flushIntervalMs = value
            return self
        }

        @discardableResult
        public func debugLogging(_ value: Bool) -> Builder {
            debugLogging = value
            return self
        }

        @discardableResult
        public func watchdogTimeoutMs(_ value: TimeInterval) -> Builder {
            watchdogTimeoutMs = value
            return self
        }

        public func build() -> Config {
            Config(builder: self)
        }
    }
}
