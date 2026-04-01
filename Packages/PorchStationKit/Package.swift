// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PorchStationKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PorchStationKit", targets: ["PorchStationKit"])
    ],
    targets: [
        .target(name: "PorchStationKit")
    ]
)
