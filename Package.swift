// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "RandomOracle",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RandomOracle",
            resources: [.copy("Resources/bible.tsv")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "RandomOracleTests",
            dependencies: ["RandomOracle"]
        ),
    ]
)
