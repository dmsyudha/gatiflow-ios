import Foundation

public struct SessionPayload {
    public let sessionId: String
    public let userId: String?
    public let deviceId: String
    public let appVersion: String
    public let osVersion: String
    public let deviceModel: String
    public let country: String
}
