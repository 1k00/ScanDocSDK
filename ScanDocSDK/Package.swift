// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScanDocSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ScanDocSDK",
            targets: ["ScanDocSDK"]
        ),
    ],
    targets: [
        .target(
            name: "ScanDocSDK",
            dependencies: [
                // Add external dependencies here if needed, e.g.:
                // .product(name: "NFCPassportReader", package: "NFCPassportReader")
            ],
            path: "Sources/ScanDocCameraView"
        ),
        .testTarget(
            name: "scandoc_sdkTests",
            dependencies: ["scandoc_sdk"],
            path: "Tests/scandoc_sdkTests"
        ),
    ]
)
