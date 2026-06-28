// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Elo",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Elo",
            path: "Sources/Elo"
        )
    ]
)
