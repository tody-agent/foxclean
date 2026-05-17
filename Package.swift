// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FoxClean",
    defaultLocalization: "vi",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FoxCleanCore", targets: ["FoxCleanCore"]),
        .executable(name: "fox", targets: ["FoxCleanCLI"]),
    ],
    targets: [
        .target(
            name: "FoxCleanCore",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .executableTarget(
            name: "FoxCleanCLI",
            dependencies: ["FoxCleanCore"]
        ),
        .testTarget(
            name: "FoxCleanCoreTests",
            dependencies: ["FoxCleanCore"]
        ),
    ]
)
