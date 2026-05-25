import SwiftUI
import GatiFlow
import UserNotifications

@main
struct ExampleAppApp: App {

    init() {
        // ── Option A: token from Info.plist (GatiFlowAppToken key) ─────────
        // GatiFlow.shared.start()

        // ── Option B: explicit token (used here for demo clarity) ──────────
        GatiFlow.shared.start(
            appToken: "mhub_demo_token",
            services: [Crashes(), Analytics(), PushService()]
        )

        // Associate a demo user identity with all events and crashes
        GatiFlow.shared.setUserId("demo_user_42")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - APNs token forwarding
// In a real app using UIKit AppDelegate, forward the device token here:
//
// extension AppDelegate: UIApplicationDelegate {
//     func application(_ app: UIApplication,
//                      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//         GatiFlow.shared.push?.registerAPNsToken(deviceToken)
//     }
// }
//
// For SwiftUI @main without AppDelegate, use UIApplicationDelegateAdaptor:
//
// @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
