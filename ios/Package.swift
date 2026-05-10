// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "FastMDMobile",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "FastMDMobileCore",
            targets: ["FastMDMobileCore"]
        )
    ],
    targets: [
        .target(
            name: "FastMDMobileCore"
        ),
        .testTarget(
            name: "FastMDMobileCoreTests",
            dependencies: ["FastMDMobileCore"]
        )
    ]
)
