// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KafeelClient",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KafeelClient",
            path: "Sources"
        ),
    ]
)
