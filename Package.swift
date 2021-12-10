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
        .package(name: "Log4swift", url: "https://github.com/kdeda/log4swift.git", from: "1.0.5"),
        .package(name: "ZSTDSwift", url: "https://github.com/kdeda/zstd-swift.git", from: "1.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IDDSwiftCommons",
            dependencies: [
                "Log4swift",
                "ZSTDSwift"
            ]
//            resources: [
//                .copy("CenterToolBar/CenterToolBarHistory_activityButton-mask@2x.png")
//            ]
        ),
        .testTarget(
            name: "IDDSwiftCommonsTests",
            dependencies: [
                "Log4swift",
                "ZSTDSwift"
            ]
//            resources: [
//                .copy("CenterToolBar/CenterToolBarHistory_activityButton-mask@2x.png")
//            ]
        )
    ]
)
