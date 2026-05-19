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
        let appToken: String
        var baseUrl: String = "https://mobilehub.app"
        var maxCrashQueueSize: Int = 50
        var maxEventBatchSize: Int = 20
        var flushIntervalMs: TimeInterval = 30_000
        var debugLogging: Bool = false
        var watchdogTimeoutMs: TimeInterval = 5_000

        public init(appToken: String) {
            precondition(!appToken.trimmingCharacters(in: .whitespaces).isEmpty, "appToken must not be blank")
            self.appToken = appToken
        }

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
