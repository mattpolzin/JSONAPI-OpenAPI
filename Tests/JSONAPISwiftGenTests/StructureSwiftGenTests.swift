//
//  StructureSwiftGenTests.swift
//  JSONAPISwiftGenTests
//
//  Created by Mathew Polzin on 9/27/19.
//

import Foundation
import XCTest
import OpenAPIKit
@testable import JSONAPISwiftGen

class StructureSwiftGenTests: XCTestCase {
    func test_nonObjects() {
        XCTAssertThrowsError(try StructureSwiftGen(
            swiftTypeName: "hello",
            structure: JSONSchema.string.dereferenced()!,
            cascadingConformances: ["Codable"])
        )

        XCTAssertThrowsError(try StructureSwiftGen(
            swiftTypeName: "hello",
            structure: JSONSchema.array(items: .object).dereferenced()!,
            cascadingConformances: ["Codable"])
        )
    }

    func test_conformances() {
        let structure = JSONSchema.object(
            properties: [
                "hello": .string
            ]
        ).dereferenced()!

        let swiftCodeNoConformances = try? StructureSwiftGen(
            swiftTypeName: "GeneratedType",
            structure: structure
        )
        let swiftCodeTwoConformances = try? StructureSwiftGen(
            swiftTypeName: "GeneratedType",
            structure: structure,
            cascadingConformances: ["Codable", "Equatable"]
        )

        XCTAssertEqual(try? swiftCodeNoConformances?.formattedSwiftCode(),
"""
struct GeneratedType {
    let hello: String
}

"""
        )
        XCTAssertEqual(try? swiftCodeTwoConformances?.formattedSwiftCode(),
"""
struct GeneratedType: Codable, Equatable {
    let hello: String
}

"""
        )
    }

    func test_simpleObject_allRequired() {
        let structure = JSONSchema.object(
            properties: [
                "hello": .string,
                "world": .integer,
                "fancy": .array(items: .number)
            ]
        ).dereferenced()!

        let simpleObjectSwiftCode = try? StructureSwiftGen(
            swiftTypeName: "GeneratedType",
            structure: structure,
            cascadingConformances: ["Codable"]
        )

        XCTAssertEqual(try? simpleObjectSwiftCode?.formattedSwiftCode(),
"""
struct GeneratedType: Codable {
    let fancy: [Double]
    let hello: String
    let world: Int
}

"""
        )
    }

    func test_simpleObject_optional() {
        let structures = [
            JSONSchema.object(
                properties: [
                    "hello": .string(required: false)
                ]
            ).dereferenced()!,
            JSONSchema.object(
                properties: [
                    "hello": .string(nullable: true)
                ]
            ).dereferenced()!
        ]

        let swiftCodes = structures.map {
            try? StructureSwiftGen(
                swiftTypeName: "GeneratedType",
                structure: $0,
                cascadingConformances: ["Codable"]
            )
        }.compactMap { try? $0?.formattedSwiftCode() }

        print(swiftCodes[0])
        print(swiftCodes[1])

        XCTAssertEqual(swiftCodes[0],
"""
struct GeneratedType: Codable {
    let hello: String?
}

"""
        )

        XCTAssertEqual(swiftCodes[1],
"""
struct GeneratedType: Codable {
    let hello: String?
}

"""
        )
    }

    func test_complexObject_allRequired() {
        let structure = JSONSchema.object(
            properties: [
                "hello": .array(items:
                    .object(properties: [
                        "world": .string
                        ]
                    )
                ),
                "fancy": .object(
                    properties: [
                        "pants": .object(
                            properties: [
                                "deep": .boolean
                            ]
                        )
                    ]
                )
            ]
        ).dereferenced()!

        let simpleObjectSwiftCode = try? StructureSwiftGen(
            swiftTypeName: "GeneratedType",
            structure: structure,
            cascadingConformances: ["Codable"]
        )

        XCTAssertEqual(try? simpleObjectSwiftCode?.formattedSwiftCode(),
"""
struct GeneratedType: Codable {
    let fancy: Fancy
    struct Fancy: Codable {
        let pants: Pants
        struct Pants: Codable {
            let deep: Bool
        }
    }
    let hello: [Hello]
    struct Hello: Codable {
        let world: String
    }
}

"""
        )
    }
}
