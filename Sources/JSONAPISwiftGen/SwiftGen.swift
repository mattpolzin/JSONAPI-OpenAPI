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

public protocol TypedSwiftGenerator: SwiftGenerator {
    var swiftTypeName: String { get }
}

public protocol JSONSchemaSwiftGenerator: SwiftGenerator {
    var structure: JSONSchema { get }
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

internal func propertyCased(_ name: String) -> String {
    let words = name.split(whereSeparator: "_-".contains)
    let first = words.first.map { [String($0).lowercased()] } ?? []
    let casedWords = first + words.dropFirst().map { (word) -> String in
        let firstChar = word.first?.uppercased() ?? ""
        return String(firstChar + word.dropFirst())
    }
    return casedWords.joined()
}

enum SwiftTypeError: Swift.Error {
    case typeNotFound
    case placeholderTypeNotAllowed(for: JSONSchema, hint: String)
}

internal func swiftType(from schema: JSONSchema,
                        allowPlaceholders: Bool) throws -> SwiftTypeRep {
    switch schema.jsonTypeFormat {
    case nil:
        throw SwiftTypeError.typeNotFound
    case .boolean(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    case .object(_)?:
        guard allowPlaceholders else {
            throw SwiftTypeError.placeholderTypeNotAllowed(for: schema, hint: "object")
        }
        return .placeholder(name: "Swift Type", typeHint: "Any")
    case .array(_)?:
        // try to pull type out of array items def but if not
        // then bail to general placeholder functionalty
        if case .array(_, let arrayContext) = schema,
            let items = arrayContext.items {
            do {
                let itemsType = try swiftType(from: items, allowPlaceholders: allowPlaceholders)
                return .def(.init(name: "[\(itemsType.swiftCode)]"))
            } catch {}
        }

        guard allowPlaceholders else {
            throw SwiftTypeError.placeholderTypeNotAllowed(for: schema, hint: "array")
        }
        return .placeholder(name: "Swift Type", typeHint: "[Any]")
    case .number(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    case .integer(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    case .string(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    }
}
