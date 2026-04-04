// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FastMD",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        .executableTarget(
            name: "FastMD",
            resources: [
                .copy("Resources"),
            ]
        ),
        .testTarget(
            name: "FastMDTests",
            dependencies: ["FastMD"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
