// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Canvas2",
    platforms:[.macOS(.v10_11)],
    products: [.library(name: "Canvas2", targets: ["Canvas2"]),],
    targets: [
        .target(name: "Canvas2", dependencies: [], path: "Sources", exclude: ["../Example"]),
        .testTarget(name: "Canvas2Tests", dependencies: ["Canvas2"]),
    ]
)
