// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONAPIOpenAPI",
    products: [
        .library(
            name: "JSONAPIOpenAPI",
            targets: ["JSONAPIOpenAPI"]),
        .library(
            name: "JSONAPISwiftGen",
            targets: ["JSONAPISwiftGen"]),
        .executable(
          name: "openapi_2_jsonapi_swift",
          targets: ["openapi_2_jsonapi_swift"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .upToNextMinor(from: "0.2.2")),
        .package(url: "https://github.com/mattpolzin/Sampleable.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/mattpolzin/JSONAPI-Arbitrary.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/mattpolzin/JSONAPI.git", .upToNextMinor(from: "0.31.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPI.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.24.0"))
    ],
    targets: [
        .target(
            name: "JSONAPIOpenAPI",
            dependencies: ["JSONAPI", "OpenAPIKit", "AnyCodable", "JSONAPIArbitrary", "Sampleable"]
        ),
        .testTarget(
            name: "JSONAPIOpenAPITests",
            dependencies: ["JSONAPI", "JSONAPITesting", "JSONAPIOpenAPI"]
        ),
        .target(
            name: "JSONAPISwiftGen",
            dependencies: ["JSONAPI", "OpenAPIKit", "SourceKittenFramework"]
        ),
        .testTarget(
            name: "JSONAPISwiftGenTests",
            dependencies: ["JSONAPISwiftGen"]
        ),
        .target(
          name: "openapi_2_jsonapi_swift",
          dependencies: ["JSONAPISwiftGen", "OpenAPIKit"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
