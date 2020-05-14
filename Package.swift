// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "JSONAPI-OpenAPI",
    products: [
        .library(
            name: "JSONAPIOpenAPI",
            targets: ["JSONAPIOpenAPI"]),
        .library(
            name: "JSONAPISwiftGen",
            targets: ["JSONAPISwiftGen"]),
        .library(
            name: "JSONAPIVizGen",
            targets: ["JSONAPIVizGen"])
    ],
    dependencies: [
        .package(url: "https://github.com/mattpolzin/Sampleable", from: "2.0.0"),
        .package(url: "https://github.com/mattpolzin/JSONAPI", from: "4.0.0-alpha.2"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit", from: "1.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIReflection", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/typelift/SwiftCheck", .upToNextMinor(from: "0.12.0")),
        .package(url: "https://github.com/jpsim/SourceKitten", .upToNextMinor(from: "0.29.0")),
        .package(name: "NonEmpty", url: "https://github.com/pointfreeco/swift-nonempty", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/mattpolzin/JSONAPIViz", .upToNextMinor(from: "0.0.3"))
    ],
    targets: [
        .target(
            name: "JSONAPIOpenAPI",
            dependencies: [
                "JSONAPI",
                "OpenAPIKit",
                "OpenAPIReflection",
                "Sampleable"
            ]
        ),
        .testTarget(
            name: "JSONAPIOpenAPITests",
            dependencies: [
                "JSONAPI",
                .product(name: "JSONAPITesting", package: "JSONAPI"),
                "JSONAPIOpenAPI",
                "SwiftCheck"
            ]
        ),
        .target(
            name: "JSONAPISwiftGen",
            dependencies: [
                "JSONAPI",
                "OpenAPIKit",
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "NonEmpty", package: "NonEmpty")
            ]
        ),
        .testTarget(
            name: "JSONAPISwiftGenTests",
            dependencies: [
                "JSONAPISwiftGen",
                .product(name: "JSONAPITesting", package: "JSONAPI"),
                "JSONAPIOpenAPI"
            ]
        ),
        .target(
            name: "JSONAPIVizGen",
            dependencies: [
                "JSONAPISwiftGen",
                "JSONAPIViz"
            ]
        ),
        .testTarget(
            name: "JSONAPIVizGenTests",
            dependencies: [
                "OpenAPIKit",
                "JSONAPISwiftGen",
                "JSONAPIVizGen"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
