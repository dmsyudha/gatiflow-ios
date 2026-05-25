import SwiftUI
import GatiFlow

// NOTE: To enable real push notifications in your own app:
// 1. Enable Push Notifications capability in Xcode → Signing & Capabilities.
// 2. Request permission (see ExampleAppApp.swift).
// 3. Forward the APNs token in AppDelegate:
//
//    func application(_ app: UIApplication,
//                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        GatiFlow.shared.push?.registerAPNsToken(deviceToken)
//    }
//
// 4. Include PushService() in GatiFlow.shared.start(services: [..., PushService()]).
// See sdk/ios/README.md for full setup instructions.

struct PushDemoView: View {
    @State private var log: [String] = []
    @State private var permissionStatus = "Unknown"

    var body: some View {
        List {
            Section {
                LabeledContent("Permission") {
                    Text(permissionStatus)
                        .foregroundStyle(permissionStatus == "Authorized" ? .green : .secondary)
                        .fontWeight(.medium)
                }
            } header: {
                Text("Status")
            }

            Section {
                Button("Register Push Token (demo)") {
                    // In a real app the token comes from
                    // didRegisterForRemoteNotificationsWithDeviceToken.
                    // Here we simulate with a placeholder.
                    let demoToken = "demo_apns_token_\(Int(Date().timeIntervalSince1970))"
                    GatiFlow.shared.push?.registerToken(demoToken, platform: "IOS")
                    addLog("✓ Token registered (demo)")
                }

                Button("Unregister Push Token") {
                    GatiFlow.shared.push?.unregisterToken("demo_apns_token")
                    addLog("✓ Token unregistered")
                }
                .foregroundStyle(.red)

                Button("Request Permission") {
                    requestPushPermission()
                }
            } header: {
                Text("Actions")
            }

            if !log.isEmpty {
                Section {
                    ForEach(log, id: \.self) { entry in
                        Text(entry)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Log")
                }
            }
        }
        .navigationTitle("Push Notifications")
        .onAppear { checkPermission() }
    }

    // MARK: - Helpers

    private func addLog(_ message: String) {
        log.insert(message, at: 0)
    }

    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:   permissionStatus = "Authorized"
                case .denied:       permissionStatus = "Denied"
                case .notDetermined: permissionStatus = "Not asked yet"
                case .provisional:  permissionStatus = "Provisional"
                default:            permissionStatus = "Unknown"
                }
            }
        }
    }

    private func requestPushPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    permissionStatus = granted ? "Authorized" : "Denied"
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                        addLog("✓ Permission granted — awaiting APNs token")
                    } else {
                        addLog("✗ Permission denied")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack { PushDemoView() }
}
