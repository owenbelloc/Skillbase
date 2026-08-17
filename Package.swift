// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Skillbase",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Skillbase", targets: ["Skillbase"])
    ],
    targets: [
        .executableTarget(
            name: "Skillbase",
            path: "Sources/Skillbase"
        )
    ]
)
