//
//  SwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

public protocol SwiftGenerator: SwiftCodeRepresentable {
    var decls: [Decl] { get }
}

extension SwiftGenerator {
    public var swiftCode: String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
    }
}

/// A Swift code generator that produces 1 or more Swift Types.
public protocol SwiftTypeGenerator: SwiftGenerator {
    /// The Type names that should be considered by outside
    /// code. Any types not in this list are likely only used to
    /// produce other types that do appear in this list.
    var exportedSwiftTypeNames: Set<String> { get }
}

/// A Swift code generator that produces a Swift function.
public protocol SwiftFunctionGenerator: SwiftGenerator {
    var functionName: String { get }
}

public protocol JSONSchemaSwiftGenerator: SwiftGenerator {
    var structure: DereferencedJSONSchema { get }
}

internal struct LiteralSwiftCode: SwiftCodeRepresentable, Decl, ExpressibleByStringLiteral {
    let swiftCode: String

    public init(stringLiteral value: String) {
        swiftCode = value
    }

    public init(_ value: String) {
        swiftCode = value
    }
}

internal func swiftPlaceholder(name: String, type: SwiftTypeRep) -> String {
    return "<#T##\(name)##"
        + type.swiftCode
        + "#>"
}

internal func typeCased(_ name: String) -> String {
    let words = name.split(whereSeparator: "_-".contains)
    let casedWords = words.map { word -> String in
        let firstChar = word.first?.uppercased() ?? ""
        return String(firstChar + word.dropFirst())
    }
    return casedWords.joined()
}

/// Takes a String and attemts to turn it into a reasonable property name
/// using the camel-cased conventions of Swift.
internal func propertyCased(_ name: String) -> String {
    let words = name.split(whereSeparator: "_-".contains)
    let first = words.first.map { [String($0).lowercased()] } ?? []
    let casedWords = first + words.dropFirst().map { (word) -> String in
        let firstChar = word.first?.uppercased() ?? ""
        return String(firstChar + word.dropFirst())
    }
    return casedWords.joined()
}

/// Takes a String and simply makes it safe for use in a property name, not
/// transforming to camel-cased.
internal func safeForPropertyName(_ name: String) -> String {
    return name
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "\n", with: "_")
        .replacingOccurrences(of: "-", with: "_")
}

enum SwiftTypeError: Swift.Error {
    case typeNotFound
    case placeholderTypeNotAllowed(for: JSONSchema, hint: String)
}

internal func swiftType(
    from schema: DereferencedJSONSchema,
    allowPlaceholders: Bool,
    handleOptionality: Bool = true
) throws -> SwiftTypeRep {

    let optional = handleOptionality
        ? !schema.required || schema.nullable
        : false

    let typeRep: SwiftTypeRep
    switch schema.jsonTypeFormat {
    case nil:
        throw SwiftTypeError.typeNotFound
    case .boolean(let format)?:
        typeRep = SwiftTypeRep(type(of: format).SwiftType.self)
    case .object(_)?:
        guard allowPlaceholders else {
            throw SwiftTypeError.placeholderTypeNotAllowed(for: schema.underlyingJsonSchema, hint: "object")
        }
        typeRep = .placeholder(name: "Swift Type", typeHint: "Any")
    case .array(_)?:
        // try to pull type out of array items def but if not
        // then bail to general placeholder functionalty
        if case .array(_, let arrayContext) = schema,
            let items = arrayContext.items {
            do {
                let itemsType = try swiftType(
                    from: items,
                    allowPlaceholders: allowPlaceholders,
                    handleOptionality: handleOptionality
                )
                typeRep = .def(.init(name: "[\(itemsType.swiftCode)]"))
                break
            } catch {}
        }

        guard allowPlaceholders else {
            throw SwiftTypeError.placeholderTypeNotAllowed(for: schema.underlyingJsonSchema, hint: "array")
        }
        typeRep = .placeholder(name: "Swift Type", typeHint: "[Any]")
    case .number(let format)?:
        typeRep = SwiftTypeRep(type(of: format).SwiftType.self)
    case .integer(let format)?:
        typeRep = SwiftTypeRep(type(of: format).SwiftType.self)
    case .string(let format)?:
        typeRep = SwiftTypeRep(type(of: format).SwiftType.self)
    }
    return optional ? typeRep.optional : typeRep
}
