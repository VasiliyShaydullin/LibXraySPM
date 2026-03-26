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
            checksum: "09a6730208a5f45acb0313ea372efa4ecd5ddf3db2cb16113c3ea5ef3653f153"
        )
    ]
)
