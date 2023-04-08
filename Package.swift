// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-swift-commons",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "SwiftCommons",
            targets: ["SwiftCommons"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", "1.2.5" ..< "2.0.0"),
        .package(url: "https://github.com/kdeda/idd-zstd-swift.git", "1.2.5" ..< "2.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftCommons",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift")
            ]
        ),
        .testTarget(
            name: "SwiftCommonsTests",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift")
            ]
        )
    ]
)
