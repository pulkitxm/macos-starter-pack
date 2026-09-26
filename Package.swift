// swift-tools-version: 6.0
import PackageDescription

let appName = "Starter"

let package = Package(
    name: appName,
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: appName, targets: ["Main"])
    ],
    targets: [
        .target(name: "AppCore"),
        .executableTarget(name: "Main", dependencies: ["AppCore"]),
        .testTarget(name: "AppCoreTests", dependencies: ["AppCore"]),
    ]
)
