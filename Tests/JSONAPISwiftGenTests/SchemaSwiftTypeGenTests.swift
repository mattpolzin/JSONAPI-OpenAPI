//
//  SchemaSwiftTypeGenTests.swift
//  JSONAPISwiftGenTests
//
//  Created by Mathew Polzin on 9/27/19.
//

import Foundation
import XCTest
@testable import JSONAPISwiftGen

class SchemaSwiftTypeGenTests: XCTestCase {
    func test_string() {
        XCTAssertEqual(try? swiftType(from: .string,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(String.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .string,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(String.self).swiftCode)
    }

    func test_integer() {
        XCTAssertEqual(try? swiftType(from: .integer,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Int.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .integer,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Int.self).swiftCode)
    }

    func test_double() {
        XCTAssertEqual(try? swiftType(from: .number,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .number,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)

        XCTAssertEqual(try? swiftType(from: .number(format: .double),
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .number(format: .double),
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)

        XCTAssertEqual(try? swiftType(from: .number(format: .float),
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .number(format: .float),
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Double.self).swiftCode)
    }

    func test_boolean() {
        XCTAssertEqual(try? swiftType(from: .boolean,
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep(Bool.self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .boolean,
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep(Bool.self).swiftCode)
    }

    func test_array_simple() {
        XCTAssertEqual(try? swiftType(from: .array(items: .string),
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep([String].self).swiftCode)
        XCTAssertEqual(try? swiftType(from: .array(items: .string),
                                      allowPlaceholders: false).swiftCode,
                       SwiftTypeRep([String].self).swiftCode)
    }

    func test_array_complex() {
        // with known nested type
        XCTAssertEqual(try? swiftType(from: .array(items: .object),
                                      allowPlaceholders: true).swiftCode,
                       "[" + SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "Any").swiftCode + "]")

        // without known nested type
        XCTAssertEqual(try? swiftType(from: .array(),
                                      allowPlaceholders: true).swiftCode,
                       SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "[Any]").swiftCode)

        // nesting even deeper
        XCTAssertEqual(try? swiftType(from: .array(items: .array()),
            allowPlaceholders: true).swiftCode,
                       "[" + SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "[Any]").swiftCode + "]")

        // without placeholders enabled
        XCTAssertThrowsError(try swiftType(from: .array(items: .object),
                                      allowPlaceholders: false))
    }

    func test_object() {
        // with placeholders enabled
        XCTAssertEqual(try? swiftType(from: .object,
            allowPlaceholders: true).swiftCode,
                       SwiftTypeRep.placeholder(name: "Swift Type", typeHint: "Any").swiftCode)

        // without placeholders enabled
        XCTAssertThrowsError(try swiftType(from: .object,
                                           allowPlaceholders: false))
    }
}
