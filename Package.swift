// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "createicns",
    products: [
        .executable(name: "createicns", targets: ["Frontend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
        .package(url: "https://github.com/swhitty/SwiftDraw", from: "0.14.0"),
    ],
    targets: [
        .target(
            name: "Backend",
            dependencies: [
                .product(name: "SwiftDraw", package: "SwiftDraw"),
            ]
        ),
        .executableTarget(
            name: "Frontend",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "Backend"),
            ]
        ),
    ]
)
