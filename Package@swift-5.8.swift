// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Refresher",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Refresher",
            targets: ["Refresher"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "1.0.0"),
        .package(url: "https://github.com/gh123man/SwiftUI-RenderLock", from: "1.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Refresher",
            dependencies: [
                .product(
                    name: "SwiftUIIntrospect",
                    package: "SwiftUI-Introspect"),
                .product(
                    name: "RenderLock",
                    package: "SwiftUI-RenderLock")
            ]
        ),
    ]
)
