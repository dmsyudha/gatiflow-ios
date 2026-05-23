import SwiftUI
import GatiFlow

struct CrashDemoView: View {
    @State private var log: [LogEntry] = []
    @State private var userId: String = "demo_user_42"

    var body: some View {
        List {
            Section("Handled Errors") {
                Button {
                    struct NetworkError: Error, LocalizedError {
                        var errorDescription: String? { "Request timed out after 30 s" }
                    }
                    GatiFlow.shared.crashes?.trackError(
                        NetworkError(),
                        metadata: ["endpoint": "/api/products", "timeout_ms": "30000"]
                    )
                    log("Reported NetworkError  { endpoint: /api/products }")
                } label: {
                    Label("Report network error", systemImage: "wifi.slash")
                }

                Button {
                    struct PaymentError: Error, LocalizedError {
                        let code: Int
                        var errorDescription: String? { "Payment declined (code \(code))" }
                    }
                    GatiFlow.shared.crashes?.trackError(
                        PaymentError(code: 4001),
                        metadata: ["checkout_step": "validate_card", "retry_count": "2"]
                    )
                    log("Reported PaymentError  { code: 4001 }")
                } label: {
                    Label("Report payment error", systemImage: "creditcard.trianglebadge.exclamationmark")
                }

                Button {
                    do {
                        throw URLError(.badServerResponse)
                    } catch {
                        GatiFlow.shared.crashes?.trackError(error, metadata: [
                            "context": "api_response_handler",
                        ])
                        log("Reported URLError.badServerResponse")
                    }
                } label: {
                    Label("Report URLError", systemImage: "server.rack")
                }
            }

            Section("User Identity") {
                HStack {
                    TextField("User ID", text: $userId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Spacer()
                    Button("Set") {
                        GatiFlow.shared.setUserId(userId.isEmpty ? nil : userId)
                        log(userId.isEmpty ? "User ID cleared" : "User ID set: \(userId)")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Button(role: .destructive) {
                    GatiFlow.shared.setUserId(nil)
                    userId = ""
                    log("User ID cleared")
                } label: {
                    Label("Clear user ID", systemImage: "person.slash")
                }
            }

            logSection
        }
        .navigationTitle("Crash Reporting")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Log

    @ViewBuilder
    private var logSection: some View {
        Section("Action Log") {
            if log.isEmpty {
                Text("Tap a button above to log actions.")
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
    NavigationStack { CrashDemoView() }
}
