// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VlessSPM",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .tvOS(.v17)
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
            dependencies: ["LibXray"],
            path: "Sources/LibXraySPM",
            linkerSettings: [
                .linkedFramework("CoreFoundation"),
                .linkedFramework("Security"),
                .linkedLibrary("resolv")
            ]
        ),
        .binaryTarget(
            name: "LibXray",
            url: "https://github.com/VasiliyShaydullin/LibXraySPM/releases/download/26.11.9/LibXray.xcframework.zip",
            checksum: "7cf2cd85998cbe4550dd584be7d8bd31f15a4313761e27f5ac94147f88e758d5"
        ),
        .testTarget(name: "VlessSPMTests", dependencies: ["VlessSPM"])
    ]
)
