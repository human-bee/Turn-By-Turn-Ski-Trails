// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SkiTrails",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SkiTrailsCore",
            targets: ["SkiTrailsCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", "10.16.0"..<"11.0.0"),
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "2.8.0"),
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.16.0"),
        .package(url: "https://github.com/mapbox/turf-swift.git", exact: "2.8.0")
    ],
    targets: [
        .target(
            name: "SkiTrailsCore",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "Turf", package: "turf-swift"),
            ],
            path: "Sources/SkiTrailsCore"
        ),
        .executableTarget(
            name: "SkiTrails",
            dependencies: [
                "SkiTrailsCore",
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "Turf", package: "turf-swift")
            ],
            path: "App/SkiTrails"
        ),
        .testTarget(
            name: "SkiTrailsCoreTests",
            dependencies: ["SkiTrailsCore"]
        )
    ]
) 