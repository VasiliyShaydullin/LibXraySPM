// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LibXraySPM",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LibXraySPM",
            targets: ["LibXraySPM"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .binaryTarget(
            name: "LibXraySPM",
            url:"https://github.com/VasiliyShaydullin/LibXraySPM/releases/download/24.10.31/LibXray.xcframework.zip",
            checksum: "09a6730208a5f45acb0313ea372efa4ecd5ddf3db2cb16113c3ea5ef3653f153"
        )
    ]
)
