// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GatiFlow",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "GatiFlow", targets: ["GatiFlow"]),
    ],
    targets: [
        .target(
            name: "GatiFlow",
            path: "Sources/GatiFlow"
        ),
        .testTarget(
            name: "GatiFlowTests",
            dependencies: ["GatiFlow"],
            path: "Tests/GatiFlowTests"
        ),
    ]
)
