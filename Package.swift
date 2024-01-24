// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "musap-ios",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "musap-ios",
            targets: ["musap-ios"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Yubico/yubikit-ios", .upToNextMajor(from: "4.4.0"))
    ],
    targets: [
        .target(
            name: "musap-ios",
            dependencies: [
                .product(name: "YubiKit", package: "yubikit-ios") // Explicitly declare the product and package name
            ],
            path: "Sources")
    ]
)
