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
        var obj: [String: Any] = [
            "exceptionClass": exceptionClass,
            "message": message,
            "stackTrace": stackTrace,
            "appVersion": appVersion,
            "osVersion": osVersion,
            "deviceId": deviceId,
            "deviceModel": deviceModel,
            "metadata": metadata,
            "occurredAt": ISO8601DateFormatter().string(from: occurredAt),
        ]
        if let userId = userId { obj["userId"] = userId }
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
        let date = (obj["occurredAt"] as? String).flatMap { formatter.date(from: $0) } ?? Date()
        let metadata = obj["metadata"] as? [String: String] ?? [:]

        return CrashPayload(
            exceptionClass: obj["exceptionClass"] as? String ?? "",
            message: obj["message"] as? String ?? "",
            stackTrace: obj["stackTrace"] as? String ?? "",
            appVersion: obj["appVersion"] as? String ?? "",
            osVersion: obj["osVersion"] as? String ?? "",
            deviceId: obj["deviceId"] as? String ?? "",
            deviceModel: obj["deviceModel"] as? String ?? "",
            userId: obj["userId"] as? String,
            metadata: metadata,
            occurredAt: date
        )
    }
}
