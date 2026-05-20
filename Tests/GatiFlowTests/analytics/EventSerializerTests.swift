import XCTest
@testable import GatiFlow

final class EventSerializerTests: XCTestCase {

    private let session = SessionPayload(
        sessionId: "sess-001",
        userId: "user-001",
        deviceId: "dev-001",
        appVersion: "2.0.0",
        osVersion: "iOS 18.0",
        deviceModel: "iPhone 16",
        country: "US"
    )

    // MARK: - Session block

    func test_sessionFieldsPresent() throws {
        let body = EventSerializer.toRequestBody(events: [], session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let s = root["session"] as! [String: Any]
        XCTAssertEqual(s["sessionId"] as? String, "sess-001")
        XCTAssertEqual(s["userId"] as? String, "user-001")
        XCTAssertEqual(s["deviceId"] as? String, "dev-001")
        XCTAssertEqual(s["appVersion"] as? String, "2.0.0")
        XCTAssertEqual(s["osVersion"] as? String, "iOS 18.0")
        XCTAssertEqual(s["deviceModel"] as? String, "iPhone 16")
        XCTAssertEqual(s["country"] as? String, "US")
    }

    func test_nullUserIdOmitsKey() throws {
        let noUserSession = SessionPayload(
            sessionId: "s1", userId: nil, deviceId: "d1",
            appVersion: "1.0", osVersion: "iOS 18", deviceModel: "iPhone", country: "US"
        )
        let body = EventSerializer.toRequestBody(events: [], session: noUserSession)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let s = root["session"] as! [String: Any]
        XCTAssertNil(s["userId"])
    }

    // MARK: - Events array

    func test_emptyEventsProducesEmptyArray() throws {
        let body = EventSerializer.toRequestBody(events: [], session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [Any]
        XCTAssertEqual(arr.count, 0)
    }

    func test_eventNameSerialized() throws {
        let body = EventSerializer.toRequestBody(events: [EventPayload(name: "button_tap")], session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [[String: Any]]
        XCTAssertEqual(arr[0]["name"] as? String, "button_tap")
    }

    func test_occurredAtIsISO8601() throws {
        let fixedDate = Date(timeIntervalSince1970: 0)
        let body = EventSerializer.toRequestBody(
            events: [EventPayload(name: "test", occurredAt: fixedDate)], session: session
        )
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [[String: Any]]
        let ts = arr[0]["occurredAt"] as! String
        // ISO-8601 with fractional seconds
        let regex = try NSRegularExpression(pattern: #"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}"#)
        XCTAssertTrue(regex.firstMatch(in: ts, range: NSRange(ts.startIndex..., in: ts)) != nil)
    }

    func test_propertiesSerializedAsNestedObject() throws {
        let events = [EventPayload(name: "purchase", properties: ["product_id": "abc", "price": 9.99])]
        let body = EventSerializer.toRequestBody(events: events, session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [[String: Any]]
        let props = arr[0]["properties"] as! [String: Any]
        XCTAssertEqual(props["product_id"] as? String, "abc")
        XCTAssertEqual(props["price"] as? Double ?? 0, 9.99, accuracy: 0.001)
    }

    func test_noPropertiesKeyWhenNil() throws {
        let body = EventSerializer.toRequestBody(events: [EventPayload(name: "app_open")], session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [[String: Any]]
        XCTAssertNil(arr[0]["properties"])
    }

    func test_multipleEventsInOrder() throws {
        let events = [
            EventPayload(name: "first"),
            EventPayload(name: "second"),
            EventPayload(name: "third"),
        ]
        let body = EventSerializer.toRequestBody(events: events, session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [[String: Any]]
        XCTAssertEqual(arr.count, 3)
        XCTAssertEqual(arr[0]["name"] as? String, "first")
        XCTAssertEqual(arr[1]["name"] as? String, "second")
        XCTAssertEqual(arr[2]["name"] as? String, "third")
    }

    // MARK: - Top-level structure

    func test_rootHasSessionAndEventsKeys() throws {
        let body = EventSerializer.toRequestBody(events: [], session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        XCTAssertNotNil(root["session"])
        XCTAssertNotNil(root["events"])
    }

    func test_outputIsValidJson() {
        let body = EventSerializer.toRequestBody(
            events: [EventPayload(name: "e1", properties: ["k": "v"])],
            session: session
        )
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(body.utf8)))
    }

    func test_largeBatchSerializes() throws {
        let events = (1...100).map { EventPayload(name: "event_\($0)") }
        let body = EventSerializer.toRequestBody(events: events, session: session)
        let root = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
        let arr = root["events"] as! [Any]
        XCTAssertEqual(arr.count, 100)
    }
}
