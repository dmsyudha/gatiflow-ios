import Foundation

public struct EventPayload {
    public let name: String
    public let properties: [String: Any]?
    public let occurredAt: Date

    public init(name: String, properties: [String: Any]? = nil, occurredAt: Date = Date()) {
        self.name = name
        self.properties = properties
        self.occurredAt = occurredAt
    }
}

enum EventSerializer {
    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func toRequestBody(events: [EventPayload], session: SessionPayload) -> String {
        var sessionObj: [String: Any] = [
            "sessionId": session.sessionId,
            "deviceId": session.deviceId,
            "appVersion": session.appVersion,
            "osVersion": session.osVersion,
            "deviceModel": session.deviceModel,
            "country": session.country,
        ]
        if let userId = session.userId { sessionObj["userId"] = userId }

        let eventsArr: [[String: Any]] = events.map { e in
            var obj: [String: Any] = [
                "name": e.name,
                "occurredAt": iso8601.string(from: e.occurredAt),
            ]
            if let props = e.properties { obj["properties"] = props }
            return obj
        }

        let root: [String: Any] = ["session": sessionObj, "events": eventsArr]
        guard let data = try? JSONSerialization.data(withJSONObject: root),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
