// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONAPIOpenAPI",
    products: [
        .library(
            name: "JSONAPIOpenAPI",
            targets: ["JSONAPIOpenAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mattpolzin/Sampleable.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/mattpolzin/JSONAPI.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPIKit.git", .upToNextMinor(from: "0.29.0")),
        .package(url: "https://github.com/mattpolzin/OpenAPIReflection.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/typelift/SwiftCheck.git", .upToNextMinor(from: "0.12.0"))
    ],
    targets: [
        .target(
            name: "JSONAPIOpenAPI",
            dependencies: ["JSONAPI", "OpenAPIKit", "OpenAPIReflection", "Sampleable"]),
        .testTarget(
            name: "JSONAPIOpenAPITests",
            dependencies: ["JSONAPI", "JSONAPITesting", "JSONAPIOpenAPI", "SwiftCheck"])
    ],
    swiftLanguageVersions: [.v5]
)
