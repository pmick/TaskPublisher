// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TaskPublisher",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TaskPublisher",
            targets: ["TaskPublisher"]),
    ],
    targets: [
        .target(
            name: "TaskPublisher",
            dependencies: []),
        .testTarget(
            name: "TaskPublisherTests",
            dependencies: ["TaskPublisher"]),
    ]
)
