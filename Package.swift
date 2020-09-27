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
        .package(url: "https://github.com/mattpolzin/Sampleable.git", from: "2.0.0"),
        .package(url: "https://github.com/mattpolzin/JSONAPI.git", from: "5.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "1.4.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIReflection.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/typelift/SwiftCheck.git", .upToNextMinor(from: "0.12.0")),
        .package(url: "https://github.com/apple/swift-format.git", from: "0.50300.0"),
        .package(name: "NonEmpty", url: "https://github.com/pointfreeco/swift-nonempty.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/mattpolzin/JSONAPIViz.git", .exact("0.0.6"))
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
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "SwiftFormatConfiguration", package: "swift-format"),
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
