// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobileHub",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "MobileHub", targets: ["MobileHub"]),
    ],
    targets: [
        .target(
            name: "MobileHub",
            path: "Sources/MobileHub"
        ),
        .testTarget(
            name: "MobileHubTests",
            dependencies: ["MobileHub"],
            path: "Tests/MobileHubTests"
        ),
    ]
)
