// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LibXraySPM",
    platforms: [
            .iOS(.v15)
        ],
    products: [
        .library(
            name: "LibXraySPM",
            targets: ["LibXraySPM"]
        ),
    ],
    targets: [
        .target(
            name: "LibXraySPM",
            dependencies: ["LibXray"],
            path: "Sources/LibXraySPM",
            linkerSettings: [
                .linkedLibrary("resolv")
            ]
        ),
        .binaryTarget(
            name: "LibXray",
            url:"https://github.com/VasiliyShaydullin/LibXraySPM/releases/download/25.12.8/LibXray.xcframework.zip",
            checksum: "95c9ea1cb7757fe2287e590351401fb44b85b00372a29ef1331fc6685d5ad415"
        )
    ]
)
