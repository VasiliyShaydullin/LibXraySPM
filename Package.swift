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
            url:"https://github.com/VasiliyShaydullin/LibXraySPM/releases/download/24.12.18/LibXray.xcframework.zip",
            checksum: "d3e494fe452c58fb8febb51d117fd0ebeaaaa14d46d45f1a8448bdb6a14142a9"
        )
    ]
)
