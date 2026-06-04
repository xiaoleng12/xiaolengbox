// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XiaoLengBox",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "XiaoLengBox",
            path: "Sources/XiaoLengBox"
        ),
        .testTarget(
            name: "XiaoLengBoxTests",
            dependencies: ["XiaoLengBox"],
            path: "Tests/XiaoLengBoxTests"
        )
    ]
)
