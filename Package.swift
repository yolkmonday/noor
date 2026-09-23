// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Noor",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "adhan-swift"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Noor",
            dependencies: [
                .product(name: "Adhan", package: "adhan-swift"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Noor",
            exclude: ["Info.plist", "Noor.entitlements", "Adhan", "Resources"]
        )
    ]
)
