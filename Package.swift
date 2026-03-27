// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VlessSPM",
    platforms: [
            .iOS(.v15)
        ],
    products: [
        .library(
            name: "VlessSPM",
            targets: ["VlessSPM"]
        ),
    ],
    targets: [
        .target(
            name: "VlessSPM",
            dependencies: ["Vless"],
            path: "Sources/LibXraySPM",
            linkerSettings: [
                .linkedLibrary("resolv")
            ]
        ),
        .binaryTarget(
            name: "Vless",
            url: "https://github.com/VasiliyShaydullin/LibXraySPM/releases/download/25.12.8-vless.1/Vless.xcframework.zip",
            checksum: "cc917a1dce12cb697153a8091bb148826496c43cea9776470aa36d13c301a403"
        )
    ]
)
