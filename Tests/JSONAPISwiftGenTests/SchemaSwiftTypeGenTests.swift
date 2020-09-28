//
//  SchemaSwiftTypeGenTests.swift
//  JSONAPISwiftGenTests
//
//  Created by Mathew Polzin on 9/27/19.
//

import Foundation
import XCTest
import OpenAPIKit
@testable import JSONAPISwiftGen

class SchemaSwiftTypeGenTests: XCTestCase {
    func test_string() {
        XCTAssertEqual(try? swiftType(from: JSONSchema.string.dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(String.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.string.dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(String.self).swiftCode)
    }

    func test_integer() {
        XCTAssertEqual(try? swiftType(from: JSONSchema.integer.dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Int.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.integer.dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Int.self).swiftCode)
    }

    func test_double() {
        XCTAssertEqual(try? swiftType(from: JSONSchema.number.dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.number.dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)

        XCTAssertEqual(try? swiftType(from: JSONSchema.number(format: .double).dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.number(format: .double).dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)

        XCTAssertEqual(try? swiftType(from: JSONSchema.number(format: .float).dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.number(format: .float).dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
    }

    func test_boolean() {
        XCTAssertEqual(try? swiftType(from: JSONSchema.boolean.dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Bool.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.boolean.dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Bool.self).swiftCode)
    }

    func test_array_simple() {
        XCTAssertEqual(try? swiftType(from: JSONSchema.array(items: .string).dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep([String].self).swiftCode)
        XCTAssertEqual(try? swiftType(from: JSONSchema.array(items: .string).dereferenced()!,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep([String].self).swiftCode)
    }

    func test_array_complex() {
        // with known nested type
        XCTAssertEqual(try? swiftType(from: JSONSchema.array(items: .object).dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       "[" + SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "Any").swiftCode + "]")

        // without known nested type
        XCTAssertEqual(try? swiftType(from: JSONSchema.array().dereferenced()!,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "[Any]").swiftCode)

        // nesting even deeper
        XCTAssertEqual(try? swiftType(from: JSONSchema.array(items: .array()).dereferenced()!,
            allowPlaceholders: true).swiftCode,
                       "[" + SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "[Any]").swiftCode + "]")

        // without placeholders enabled
        XCTAssertThrowsError(try swiftType(from: JSONSchema.array(items: .object).dereferenced()!,
                                      allowPlaceholders: false))
    }

    func test_object() {
        // with placeholders enabled
        XCTAssertEqual(try? swiftType(from: JSONSchema.object.dereferenced()!,
            allowPlaceholders: true).swiftCode,
                       SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "Any").swiftCode)

        // without placeholders enabled
        XCTAssertThrowsError(try swiftType(from: JSONSchema.object.dereferenced()!,
                                           allowPlaceholders: false))
    }
}
