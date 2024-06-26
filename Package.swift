// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "createicns",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "createicns", targets: ["Frontend"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/swhitty/SwiftDraw", from: "0.15.0"),
    ],
    targets: [
        .target(
            name: "Backend",
            dependencies: [
                "SwiftDraw",
            ]
        ),
        .executableTarget(
            name: "Frontend",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Backend",
            ]
        ),
    ]
)
