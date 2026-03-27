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
            checksum: "4b2335a3a57eb0ecb07472ce129cac8015e735ca3532e89982de9bd0998865b5"
        )
    ]
)
