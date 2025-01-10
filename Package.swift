// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "SkiTrailsCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SkiTrailsCore",
            targets: ["SkiTrailsCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", .upToNextMajor(from: "10.15.0")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", .upToNextMajor(from: "8.17.2"))
    ],
    targets: [
        .target(
            name: "SkiTrailsCore",
            dependencies: [
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ],
            path: "Sources/SkiTrailsCore"
        ),
        .testTarget(
            name: "SkiTrailsTests",
            dependencies: ["SkiTrailsCore"],
            path: "Tests/SkiTrailsTests"
        )
    ]
) 