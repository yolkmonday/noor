// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Noor",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "adhan-swift")
    ],
    targets: [
        .executableTarget(
            name: "Noor",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift")
            ],
            path: "Noor",
            exclude: ["Info.plist", "Noor.entitlements", "Adhan", "Resources"]
        )
    ]
)
