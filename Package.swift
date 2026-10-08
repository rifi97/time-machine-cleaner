// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TimeMachineCleaner",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TimeMachineCleaner", targets: ["TimeMachineCleaner"])
    ],
    targets: [
        .executableTarget(
            name: "TimeMachineCleaner",
            path: "Sources/SnapshotCleaner"
        ),
        .testTarget(
            name: "TimeMachineCleanerTests",
            dependencies: ["TimeMachineCleaner"],
            path: "Tests/SnapshotCleanerTests"
        )
    ]
)
