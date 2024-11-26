// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "poweredge-r410-fanctrl",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "fanctrl", targets: ["fanctrl"]),
        .library(name: "IPMITool", targets: ["IPMITool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "fanctrl",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .target(name: "IPMITool"),
            ]
        ),
        .target(
            name: "IPMITool",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
    ]
)
