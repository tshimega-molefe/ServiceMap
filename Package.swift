// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServiceMap",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ServiceMap",
            targets: ["ServiceMap"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
       .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", .upToNextMajor(from: "0.45.0")),
       .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", branch: "main"),
       .package(url: "https://github.com/mapbox/mapbox-navigation-ios.git", branch: "main"),
       .package(name: "MapboxDirections", url: "https://github.com/mapbox/mapbox-directions-swift.git", from: "2.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ServiceMap",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "MapboxCoreNavigation", package: "mapbox-navigation-ios"),
                .product(name: "MapboxNavigation", package: "mapbox-navigation-ios"),
                .product(name: "MapboxDirections", package: "MapboxDirections"),
                
                // Latest prerelease
            ]
        ),
        .testTarget(
            name: "ServiceMapTests",
            dependencies: ["ServiceMap"]),
    ]
)
