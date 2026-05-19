import Foundation
import MobileHub

// ─── Helpers ──────────────────────────────────────────────────────────────────

func step(_ message: String) {
    print("\n[\(Date().formatted(.dateTime.hour().minute().second()))] \(message)")
}

func divider() { print(String(repeating: "─", count: 60)) }

// ─── 1. Configure & Start ─────────────────────────────────────────────────────

divider()
print("  MobileHub SDK — Example App (macOS)")
divider()

let config = Config.Builder(appToken: "mhub_example_token_demo")
    .baseUrl("http://localhost:8080")   // point at a local dev server; network errors are non-fatal
    .debugLogging(true)
    .flushIntervalMs(3_000)
    .watchdogTimeoutMs(5_000)
    .build()

step("Starting SDK…")
MobileHub.shared.start(
    config: config,
    services: [Crashes(), Analytics()]
)

// ─── 2. Identify the User ─────────────────────────────────────────────────────

step("Setting user identity…")
MobileHub.shared.setUserId("user_demo_42")
print("    userId = user_demo_42")

// ─── 3. Track Analytics Events ───────────────────────────────────────────────

step("Tracking analytics events…")

MobileHub.shared.analytics?.trackEvent("app_opened")
print("    ✓ app_opened")

MobileHub.shared.analytics?.trackEvent("screen_viewed", properties: [
    "screen_name": "home",
    "referrer": "push_notification",
])
print("    ✓ screen_viewed  { screen_name: home, referrer: push_notification }")

MobileHub.shared.analytics?.trackEvent("button_tapped", properties: [
    "screen": "home",
    "button": "get_started",
])
print("    ✓ button_tapped  { screen: home, button: get_started }")

MobileHub.shared.analytics?.trackEvent("purchase_completed", properties: [
    "item_id": "pro_monthly",
    "price_usd": 9.99,
    "currency": "USD",
])
print("    ✓ purchase_completed  { item_id: pro_monthly, price_usd: 9.99 }")

// ─── 4. Report Handled Errors ─────────────────────────────────────────────────

step("Reporting handled errors…")

struct PaymentError: Error, LocalizedError {
    let code: Int
    var errorDescription: String? { "Payment declined — code \(code)" }
}

MobileHub.shared.crashes?.trackError(
    PaymentError(code: 4001),
    metadata: [
        "checkout_step": "validate_card",
        "retry_count": "2",
        "card_type": "visa",
    ]
)
print("    ✓ Handled error reported  { code: 4001, step: validate_card }")

struct NetworkError: Error, LocalizedError {
    var errorDescription: String? { "Request timed out after 30 s" }
}

MobileHub.shared.crashes?.trackError(
    NetworkError(),
    metadata: ["endpoint": "/api/products", "timeout_ms": "30000"]
)
print("    ✓ Handled error reported  { endpoint: /api/products }")

// ─── 5. Enable / Disable at Runtime ──────────────────────────────────────────

step("Demonstrating runtime opt-out…")
MobileHub.shared.analytics?.setEnabled(false)
MobileHub.shared.analytics?.trackEvent("this_event_is_dropped")
print("    Analytics disabled — event above is silently dropped")
MobileHub.shared.analytics?.setEnabled(true)
print("    Analytics re-enabled")

// ─── 6. Flush & Stop ─────────────────────────────────────────────────────────

step("Flushing event queue…")
MobileHub.shared.analytics?.flush()

// Give the HTTP layer a moment to attempt uploads before the process exits.
Thread.sleep(forTimeInterval: 1.0)

step("Stopping SDK…")
MobileHub.shared.stop()

divider()
print("  Example complete. Re-run with `swift run` in sdk/ios/Example/")
divider()
print()
