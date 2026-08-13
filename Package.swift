// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacEase",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MacEaseCore", targets: ["MacEaseCore"])
    ],
    targets: [
        .target(name: "MacEaseCore"),
        .executableTarget(
            name: "MacEaseCoreSmokeTests",
            dependencies: ["MacEaseCore"],
            path: "Tests/SmokeTests"
        )
    ]
)
