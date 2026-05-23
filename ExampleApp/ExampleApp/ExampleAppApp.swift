import SwiftUI
import GatiFlow

@main
struct ExampleAppApp: App {

    init() {
        // ── Option A: token from Info.plist (GatiFlowAppToken key) ─────────
        // GatiFlow.shared.start()

        // ── Option B: explicit token (used here for demo clarity) ──────────
        GatiFlow.shared.start(
            appToken: "mhub_demo_token",
            services: [Crashes(), Analytics()]
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
