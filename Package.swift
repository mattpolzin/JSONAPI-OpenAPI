// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONAPIOpenAPI",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "JSONAPIOpenAPI",
            targets: ["JSONAPIOpenAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.1.0"),
        .package(url: "https://github.com/mattpolzin/Sampleable.git", from: "1.0.0"),
        .package(url: "https://github.com/mattpolzin/JSONAPI-Arbitrary.git", from: "1.0.0"),
        .package(url: "https://github.com/mattpolzin/JSONAPI.git", from: "0.18.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "JSONAPIOpenAPI",
            dependencies: ["JSONAPI", "AnyCodable", "JSONAPIArbitrary", "Sampleable"]),
            .testTarget(
                name: "JSONAPIOpenAPITests",
                dependencies: ["JSONAPI", "JSONAPITesting", "JSONAPIOpenAPI"])
    ]
)
