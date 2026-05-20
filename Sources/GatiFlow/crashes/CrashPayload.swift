import Foundation

struct CrashPayload {
    let exceptionClass: String
    let message: String
    let stackTrace: String
    let appVersion: String
    let osVersion: String
    let deviceId: String
    let deviceModel: String
    let userId: String?
    let metadata: [String: String]
    let occurredAt: Date

    static func from(
        error: Error,
        appVersion: String,
        osVersion: String,
        deviceId: String,
        deviceModel: String,
        userId: String?,
        metadata: [String: String]
    ) -> CrashPayload {
        let message = error.localizedDescription
        return CrashPayload(
            exceptionClass: String(describing: type(of: error)),
            message: String(message.prefix(200)),
            stackTrace: Thread.callStackSymbols.joined(separator: "\n"),
            appVersion: appVersion,
            osVersion: osVersion,
            deviceId: deviceId,
            deviceModel: deviceModel,
            userId: userId,
            metadata: metadata,
            occurredAt: Date()
        )
    }

    static func from(
        exception: NSException,
        appVersion: String,
        osVersion: String,
        deviceId: String,
        deviceModel: String,
        userId: String?,
        metadata: [String: String]
    ) -> CrashPayload {
        let message = exception.reason ?? "no message"
        return CrashPayload(
            exceptionClass: exception.name.rawValue,
            message: String(message.prefix(200)),
            stackTrace: exception.callStackSymbols.joined(separator: "\n"),
            appVersion: appVersion,
            osVersion: osVersion,
            deviceId: deviceId,
            deviceModel: deviceModel,
            userId: userId,
            metadata: metadata,
            occurredAt: Date()
        )
    }

    func toJson() -> String {
        // title = human-readable message; reason = exception class (matches Go ingestor model)
        var obj: [String: Any] = [
            "title": String(message.prefix(200)),
            "reason": exceptionClass,
            "exception_type": exceptionClass,
            "stack_trace": stackTrace,
            "app_version": appVersion,
            "os_version": osVersion,
            "device_id": deviceId,
            "device_model": deviceModel,
            "metadata": metadata,
        ]
        if let userId = userId { obj["user_id"] = userId }
        let wrapper = ["crash": obj]
        guard let data = try? JSONSerialization.data(withJSONObject: wrapper),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    static func fromJson(_ json: String) -> CrashPayload? {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let obj = root["crash"] as? [String: Any]
        else { return nil }

        let formatter = ISO8601DateFormatter()
        let date = (obj["occurred_at"] as? String).flatMap { formatter.date(from: $0) } ?? Date()
        let metadata = obj["metadata"] as? [String: String] ?? [:]

        return CrashPayload(
            exceptionClass: obj["exception_type"] as? String ?? obj["reason"] as? String ?? "",
            message: obj["title"] as? String ?? "",
            stackTrace: obj["stack_trace"] as? String ?? "",
            appVersion: obj["app_version"] as? String ?? "",
            osVersion: obj["os_version"] as? String ?? "",
            deviceId: obj["device_id"] as? String ?? "",
            deviceModel: obj["device_model"] as? String ?? "",
            userId: obj["user_id"] as? String,
            metadata: metadata,
            occurredAt: date
        )
    }
}
