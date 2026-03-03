// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScreenRelay",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ScreenRelay",
            path: "ScreenRelay/Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
