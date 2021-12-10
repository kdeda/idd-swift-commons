// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idd-swift-commons",
    platforms: [
        // .iOS(.v13),
        .macOS(.v10_12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IDDSwiftCommons",
            targets: ["IDDSwiftCommons"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/kdeda/idd-log4-swift.git", from: "1.1.1"),
        .package(url: "https://github.com/kdeda/idd-zstd-swift.git", from: "1.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IDDSwiftCommons",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift")
            ]
//            resources: [
//                .copy("CenterToolBar/CenterToolBarHistory_activityButton-mask@2x.png")
//            ]
        ),
        .testTarget(
            name: "IDDSwiftCommonsTests",
            dependencies: [
                .product(name: "Log4swift", package: "idd-log4-swift"),
                .product(name: "ZSTDSwift", package: "idd-zstd-swift")
            ]
        )
    ]
)
