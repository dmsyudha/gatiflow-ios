# GatiFlow iOS SDK

Crash reporting, hang detection, and event analytics for iOS apps.
Drop-in replacement for Microsoft App Center — one call to initialize, zero configuration required.

![iOS 13+](https://img.shields.io/badge/iOS-13%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-FA7343)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)
![Zero dependencies](https://img.shields.io/badge/dependencies-none-lightgrey)

---

## Quick Start

### 1 — Add the package in Xcode

1. Open your project in Xcode and choose **File › Add Package Dependencies…**
2. Paste the repository URL:
   ```
   https://github.com/dmsyudha/gatiflow-ios
   ```
3. Select **Up to Next Major Version** starting from `1.0.0`.
4. Add the **GatiFlow** product to your app target.

Or add it manually to `Package.swift`:
```swift
.package(url: "https://github.com/dmsyudha/gatiflow-ios", from: "1.0.0")
// then in your target's dependencies:
.product(name: "GatiFlow", package: "gatiflow-ios")
```

### 2 — Store your token in Info.plist

Open `Info.plist` (or add via **Target › Info** tab) and add a **String** entry:

| Key | Type | Value |
|-----|------|-------|
| `GatiFlowAppToken` | String | `mhub_YOUR_APP_TOKEN_HERE` |

Optionally override the backend URL (leave out to use the default):

| Key | Type | Value |
|-----|------|-------|
| `GatiFlowBaseUrl` | String | `https://your-self-hosted.com` |

> **Tip:** For multiple environments use Xcode build configurations.
> See [Multiple environments](#multiple-environments) below.

### 3 — Initialize in your entry point

**SwiftUI:**
```swift
import SwiftUI
import GatiFlow

@main
struct MyApp: App {
    init() {
        GatiFlow.shared.start()   // token is read from Info.plist automatically
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

**UIKit (AppDelegate):**
```swift
import UIKit
import GatiFlow

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GatiFlow.shared.start()   // token is read from Info.plist automatically
        return true
    }
}
```

That's it. Crash reports and analytics start flowing immediately.

---

## Alternative: pass the token directly

Use this for quick prototyping or when you manage secrets outside Info.plist.

```swift
GatiFlow.shared.start(
    appToken: "mhub_YOUR_APP_TOKEN",
    services: [Crashes(), Analytics()]
)
```

---

## Multiple environments (staging / production)

Use Xcode build configurations to switch tokens without changing code.

1. In Xcode, select your target → **Build Settings** → add a **User-Defined Setting**:
   ```
   GATIFLOW_TOKEN = mhub_STAGING_TOKEN          (Debug configuration)
   GATIFLOW_TOKEN = mhub_PRODUCTION_TOKEN       (Release configuration)
   ```
2. In `Info.plist`, set the value to the build setting variable:
   ```xml
   <key>GatiFlowAppToken</key>
   <string>$(GATIFLOW_TOKEN)</string>
   ```

Now Debug builds use the staging token and Release builds use the production token —
no code changes, no recompile needed between environments.

---

## Crash Reporting

Unhandled exceptions, signal-based crashes, and main-thread hangs are captured automatically once `Crashes` is started.

```swift
// Report a handled error
do {
    try riskyOperation()
} catch {
    GatiFlow.shared.crashes?.trackError(error, metadata: [
        "screen":      "CheckoutScreen",
        "user_action": "tap_buy",
    ])
}

// Opt out (e.g. based on user consent)
GatiFlow.shared.crashes?.setEnabled(false)
```

---

## Analytics

```swift
// Simple event
GatiFlow.shared.analytics?.trackEvent("screen_view", properties: [
    "screen_name": "HomeScreen",
])

// Event with mixed-type properties
GatiFlow.shared.analytics?.trackEvent("purchase_completed", properties: [
    "product_id": "prod_abc123",
    "price":      9.99,
    "currency":   "USD",
])

// Force-flush before going to background
GatiFlow.shared.analytics?.flush()
```

---

## User Identity

```swift
// Set after login — attached to all subsequent crashes and events
GatiFlow.shared.setUserId("usr_abc123")

// Clear on logout
GatiFlow.shared.setUserId(nil)
```

---

## Advanced Configuration

Use `Config.Builder` for full control, or `Config.Builder.fromPlist()` to start
from plist values and override specific settings in code:

```swift
// Build entirely in code
let config = Config.Builder(appToken: "mhub_YOUR_TOKEN")
    .baseUrl("https://your-self-hosted.com")   // default: https://app.gatiflow.dev
    .debugLogging(true)                        // verbose SDK logs (disable in production)
    .maxCrashQueueSize(100)                    // crashes queued offline (default: 50)
    .maxEventBatchSize(50)                     // events per batch (default: 20)
    .flushIntervalMs(15_000)                   // flush interval ms (default: 30 000)
    .watchdogTimeoutMs(3_000)                  // hang threshold ms (default: 5 000)
    .build()

GatiFlow.shared.start(config: config, services: [Crashes(), Analytics()])
```

```swift
// Start from Info.plist values but override one setting
if let builder = Config.Builder.fromPlist() {
    let config = builder
        .debugLogging(true)
        .build()
    GatiFlow.shared.start(config: config, services: [Crashes(), Analytics()])
}
```

---

## API Reference

| Method | Description |
|--------|-------------|
| `GatiFlow.shared.start()` | Init from Info.plist · starts Crashes + Analytics |
| `GatiFlow.shared.start(services:)` | Init from Info.plist · custom service list |
| `GatiFlow.shared.start(appToken:services:)` | Init with explicit token |
| `GatiFlow.shared.start(config:services:)` | Init with full Config object |
| `GatiFlow.shared.setUserId(_:)` | Attach user identity (pass `nil` to clear) |
| `GatiFlow.shared.crashes` | Access the Crashes service |
| `GatiFlow.shared.analytics` | Access the Analytics service |
| `GatiFlow.shared.stop()` | Flush and shut down all services |
| `Config.Builder.fromPlist(bundle:)` | Create a Builder pre-populated from Info.plist |
| `crashes?.trackError(_:metadata:)` | Report a handled error with optional metadata |
| `crashes?.setEnabled(_:)` | Enable / disable crash reporting |
| `analytics?.trackEvent(_:properties:)` | Record a named event with optional properties |
| `analytics?.flush()` | Immediately flush buffered events |
| `analytics?.setEnabled(_:)` | Enable / disable analytics |

---

## Requirements

- iOS **13.0** or later (macOS 10.15+ also supported)
- Xcode **15** or later
- Swift **5.9** or later
- Swift Package Manager (bundled with Xcode)
- Zero third-party dependencies
