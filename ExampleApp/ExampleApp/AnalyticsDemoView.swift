import SwiftUI
import GatiFlow

struct AnalyticsDemoView: View {
    @State private var log: [LogEntry] = []
    @State private var analyticsEnabled = true

    var body: some View {
        List {
            Section("Track Events") {
                Button {
                    GatiFlow.shared.analytics?.trackEvent("screen_view", properties: [
                        "screen_name": "analytics_demo",
                        "referrer":    "home",
                    ])
                    log("screen_view  { screen_name: analytics_demo }")
                } label: {
                    Label("Track: screen_view", systemImage: "eye")
                }

                Button {
                    GatiFlow.shared.analytics?.trackEvent("button_tapped", properties: [
                        "button": "cta_subscribe",
                        "screen": "analytics_demo",
                    ])
                    log("button_tapped  { button: cta_subscribe }")
                } label: {
                    Label("Track: button_tapped", systemImage: "hand.tap")
                }

                Button {
                    GatiFlow.shared.analytics?.trackEvent("purchase_completed", properties: [
                        "product_id": "pro_monthly",
                        "price":      9.99,
                        "currency":   "USD",
                    ])
                    log("purchase_completed  { price: 9.99 USD }")
                } label: {
                    Label("Track: purchase_completed", systemImage: "cart.fill.badge.plus")
                }
            }

            Section("Controls") {
                Toggle("Analytics enabled", isOn: $analyticsEnabled)
                    .onChange(of: analyticsEnabled) { enabled in
                        GatiFlow.shared.analytics?.setEnabled(enabled)
                        log(enabled ? "Analytics re-enabled" : "Analytics disabled")
                    }

                Button {
                    GatiFlow.shared.analytics?.flush()
                    log("Manual flush triggered")
                } label: {
                    Label("Flush event queue", systemImage: "arrow.up.circle")
                }
            }

            logSection
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Log

    @ViewBuilder
    private var logSection: some View {
        Section("Event Log") {
            if log.isEmpty {
                Text("Tap a button above to log events.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(log) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                        Text(entry.time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        log.insert(LogEntry(message: message, time: formatter.string(from: Date())), at: 0)
    }
}

private struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let time: String
}

#Preview {
    NavigationStack { AnalyticsDemoView() }
}
