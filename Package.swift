// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "createicns",
    products: [
        .executable(name: "createicns", targets: ["CommandLineTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
        .package(url: "https://github.com/jordanbaird/Prism", from: "0.1.2"),
    ],
    targets: [
        .executableTarget(
            name: "CommandLineTool",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "Core"),
            ]
        ),
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Prism", package: "Prism"),
            ]
        ),
    ]
)
