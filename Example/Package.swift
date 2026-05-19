// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobileHubExample",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "MobileHubExample",
            dependencies: [
                .product(name: "MobileHub", package: "ios")
            ],
            path: "Sources/MobileHubExample"
        )
    ]
)
