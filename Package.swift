// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "createicns",
    products: [
        .executable(name: "createicns", targets: ["Frontend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
    ],
    targets: [
        .target(name: "Backend", dependencies: []),
        .executableTarget(
            name: "Frontend",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "Backend"),
            ]
        ),
    ]
)
