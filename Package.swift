// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XiaoLengBox",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "XiaoLengBox",
            path: "Sources/XiaoLengBox",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "XiaoLengBoxTests",
            dependencies: ["XiaoLengBox"],
            path: "Tests/XiaoLengBoxTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
