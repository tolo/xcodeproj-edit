// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "xcodeproj-cli",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "xcodeproj-cli",
            targets: ["xcodeproj-cli"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "9.4.3"),
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "xcodeproj-cli",
            dependencies: [
                "XcodeProj",
                "PathKit"
            ],
            path: "Sources/xcodeproj-cli"
        ),
        .testTarget(
            name: "xcodeproj-cliTests",
            dependencies: ["xcodeproj-cli"],
            path: "Tests/xcodeproj-cliTests"
        ),
    ]
)