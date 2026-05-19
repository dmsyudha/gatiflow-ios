import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol DeviceInfoProtocol {
    var deviceId: String { get }
    var deviceModel: String { get }
    var osVersion: String { get }
    var appVersion: String { get }
    var country: String { get }
}

final class DeviceInfo: DeviceInfoProtocol {
    private let storage: StorageManagerProtocol

    init(storage: StorageManagerProtocol) {
        self.storage = storage
    }

    var deviceId: String {
        if let existing = storage.getDeviceId() { return existing }
        let newId = UUID().uuidString
        storage.saveDeviceId(newId)
        return newId
    }

    var deviceModel: String {
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Mac"
        #endif
    }

    var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }

    var country: String {
        Locale.current.regionCode ?? "unknown"
    }
}
