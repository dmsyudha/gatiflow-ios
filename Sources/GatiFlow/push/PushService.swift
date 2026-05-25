import Foundation

/**
 * GatiFlow push notification service.
 *
 * Handles registering APNs device tokens (or FCM tokens when using Firebase iOS SDK)
 * with the GatiFlow backend so that push campaigns reach this device.
 *
 * ## Setup
 *
 * ### Option A — APNs (recommended, no Firebase dependency)
 *
 * 1. Enable Push Notifications capability in Xcode → Signing & Capabilities.
 * 2. In your `AppDelegate` (or `UNUserNotificationCenterDelegate`), request permission
 *    and forward the token to GatiFlow:
 *
 *    ```swift
 *    // AppDelegate.swift
 *    func application(_ app: UIApplication,
 *                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
 *        GatiFlow.shared.push?.registerAPNsToken(deviceToken)
 *    }
 *    ```
 *
 * ### Option B — FCM token (if you already use Firebase iOS SDK)
 *
 *    ```swift
 *    // In Messaging.messaging().token callback:
 *    GatiFlow.shared.push?.registerToken(token, platform: .ios)
 *    ```
 *
 * 3. Request permission early (e.g. in your @main App init):
 *    ```swift
 *    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
 *        DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
 *    }
 *    ```
 *
 * 4. Include `PushService()` in the services list:
 *    ```swift
 *    GatiFlow.shared.start(services: [Crashes(), Analytics(), PushService()])
 *    ```
 */
public final class PushService: GatiFlowService {

    private var http: HttpClientProtocol?
    private var storage: StorageManagerProtocol?
    private var config: Config?

    // Injected by GatiFlow.start — mirrors the Crashes/Analytics pattern
    var httpClient: HttpClientProtocol? {
        get { http }
        set { http = newValue }
    }
    var storageManager: StorageManagerProtocol? {
        get { storage }
        set { storage = newValue }
    }
    var sdkConfig: Config? {
        get { config }
        set { config = newValue }
    }

    public override init() { super.init() }

    // MARK: - Public API

    /**
     * Register a raw APNs device token (the `Data` from
     * `didRegisterForRemoteNotificationsWithDeviceToken`).
     *
     * The token is hex-encoded before being sent to the backend.
     */
    public func registerAPNsToken(_ tokenData: Data) {
        let hex = tokenData.map { String(format: "%02x", $0) }.joined()
        registerToken(hex, platform: "IOS")
    }

    /**
     * Register a string push token (APNs hex string or FCM registration token).
     *
     * - Parameters:
     *   - token: The raw token string.
     *   - platform: `"IOS"` (default) or `"ANDROID"`.
     */
    public func registerToken(_ token: String, platform: String = "IOS") {
        guard !token.isEmpty else { return }

        var body: [String: String] = ["token": token, "platform": platform]
        if let userId = storage?.getUserId() { body["userId"] = userId }

        guard let json = try? JSONSerialization.data(withJSONObject: body),
              let jsonString = String(data: json, encoding: .utf8) else { return }

        http?.postJson(
            path: "/api/sdk/push/register",
            body: jsonString,
            onSuccess: { Logger.d("PushService", "Token registered successfully") },
            onFailure: { err in Logger.e("PushService", "Token registration failed: \(err)") }
        )
    }

    /**
     * Unregister the push token — call this on sign-out or when the user
     * opts out of notifications.
     */
    public func unregisterToken(_ token: String) {
        guard !token.isEmpty,
              let json = try? JSONSerialization.data(withJSONObject: ["token": token]),
              let jsonString = String(data: json, encoding: .utf8),
              let baseUrl = config?.baseUrl,
              let appToken = config?.appToken,
              let url = URL(string: baseUrl + "/api/sdk/push/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appToken, forHTTPHeaderField: "x-app-token")
        request.httpBody = jsonString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { _, _, _ in
            Logger.d("PushService", "Token unregistered")
        }.resume()
    }
}
