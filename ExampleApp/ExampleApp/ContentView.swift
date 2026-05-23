import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: AnalyticsDemoView()) {
                        Label("Analytics", systemImage: "chart.bar.fill")
                    }
                    NavigationLink(destination: CrashDemoView()) {
                        Label("Crash Reporting", systemImage: "exclamationmark.triangle.fill")
                    }
                } header: {
                    Text("SDK Features")
                }

                Section {
                    LabeledContent("Status") {
                        Text("Running")
                            .foregroundStyle(.green)
                            .fontWeight(.medium)
                    }
                    LabeledContent("User ID") {
                        Text("demo_user_42")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("SDK Status")
                }
            }
            .navigationTitle("GatiFlow Example")
        }
    }
}

#Preview {
    ContentView()
}
