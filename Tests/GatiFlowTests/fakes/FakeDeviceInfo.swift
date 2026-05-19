import Foundation
@testable import GatiFlow

final class FakeDeviceInfo: DeviceInfoProtocol {
    var deviceId: String = "test-device-1"
    var deviceModel: String = "iPhone 16"
    var osVersion: String = "iOS 18.0.0"
    var appVersion: String = "1.0"
    var country: String = "US"
}
