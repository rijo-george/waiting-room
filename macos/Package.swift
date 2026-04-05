// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WaitingRoom",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WaitingRoom",
            path: "Sources"
        ),
    ]
)
