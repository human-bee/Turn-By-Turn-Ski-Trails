// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SkiTrails",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SkiTrailsCore",
            targets: ["SkiTrailsCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.16.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.17.1")
    ],
    targets: [
        .target(
            name: "SkiTrailsCore",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources/SkiTrailsCore"
        ),
        .testTarget(
            name: "SkiTrailsCoreTests",
            dependencies: ["SkiTrailsCore"]
        )
    ]
) 