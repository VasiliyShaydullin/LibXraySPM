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
            url:"https://github.com/VasiliyShaydullin/LibXraySPM/releases/download/24.12.19/LibXray.xcframework.zip",
            checksum: "20e5c6aad1a7312492a8bc3a1b8813b0023cd9faddaf6ab17e87200857d0fa2f"
        )
    ]
)
