// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SeemlessScreen",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SeemlessScreen",
            path: "SeemlessScreen/Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
