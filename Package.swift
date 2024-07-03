// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScanDocSDK",
    products: [
        .library(
            name: "ScanDocSDK",
            targets: ["ScanDocSDK"]),
    ],
    targets: [
        .binaryTarget(name: "ScanDocSDK",
                      path: "ScanDocSDK.xcframework")
    ]
)
