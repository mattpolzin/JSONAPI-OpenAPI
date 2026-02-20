// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "JSONAPI-OpenAPI",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
    ],
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
        .package(url: "https://github.com/mattpolzin/JSONAPI.git", from: "6.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", from: "5.0.0"),
        .package(url: "https://github.com/mattpolzin/OpenAPIReflection.git", from: "4.0.0"),
        .package(url: "https://github.com/typelift/SwiftCheck.git", .upToNextMinor(from: "0.12.0")),
        .package(url: "https://github.com/swiftlang/swift-format.git", from: "602.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-nonempty.git", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/mattpolzin/JSONAPIViz.git", exact: "0.0.7")
    ],
    targets: [
        .target(
            name: "JSONAPIOpenAPI",
            dependencies: [
                "JSONAPI",
                .product(name: "OpenAPIKit30", package: "OpenAPIKit"),
                .product(name: "OpenAPIReflection30", package: "OpenAPIReflection"),
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
                .product(name: "OpenAPIKit30", package: "OpenAPIKit"),
                .product(name: "SwiftFormat", package: "swift-format"),
                .product(name: "NonEmpty", package: "swift-nonempty")
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
    swiftLanguageModes: [.v5]
)
