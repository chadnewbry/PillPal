// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PillPal",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "PillPal", targets: ["PillPal"]),
    ],
    targets: [
        .target(
            name: "PillPal",
            path: "Sources"
        ),
        .testTarget(
            name: "PillPalTests",
            dependencies: ["PillPal"],
            path: "Tests"
        ),
    ]
)
