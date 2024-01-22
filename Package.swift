// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "musap-ios",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "musap-ios",
            targets: ["musap-ios"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Yubico/yubikit-ios", .upToNextMajor(from: "4.4.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "musap-ios"),
        .testTarget(
            name: "musap-iosTests",
            dependencies: ["musap-ios"]),
    ]
)
