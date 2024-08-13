// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "poweredge-r410-fanctrl",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "fanctrl", targets: ["fanctrl"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.70.0"),
    ],
    targets: [
        .executableTarget(
            name: "fanctrl",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "NIOCore", package: "swift-nio"),
            ]
        ),
    ]
)

for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(.enableUpcomingFeature("BareSlashRegexLiterals"))
}
