// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GatiFlowExample",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "GatiFlowExample",
            dependencies: [
                .product(name: "GatiFlow", package: "ios")
            ],
            path: "Sources/GatiFlowExample"
        )
    ]
)
