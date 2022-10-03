// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "createicns",
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.1.4"),
        .package(
            url: "https://github.com/jordanbaird/Prism",
            from: "0.0.5"),
    ],
    targets: [
        .executableTarget(
            name: "createicns",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"),
                .product(
                    name: "Prism",
                    package: "Prism"),
            ]),
    ]
)
