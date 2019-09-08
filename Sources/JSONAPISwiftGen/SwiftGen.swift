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

public protocol JSONSchemaSwiftGenerator: SwiftGenerator {
    var structure: JSONSchema { get }
}

internal func swiftPlaceholder(name: String, type: SwiftTypeRep) -> String {
    return "<#T##\(name)##"
        + type.swiftCode
        + "#>"
}

enum SwiftTypeError: Swift.Error {
    case typeNotFound
}

internal func swiftType(from schema: JSONSchema) throws -> SwiftTypeRep {
    switch schema.jsonTypeFormat {
    case nil:
        throw SwiftTypeError.typeNotFound
    case .boolean(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    case .object(_)?:
        return SwiftTypeRep(swiftPlaceholder(name: "Swift Type", type: "Any"))
    case .array(_)?:
        return SwiftTypeRep(swiftPlaceholder(name: "Swift Type", type: "[Any]"))
    case .number(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    case .integer(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    case .string(let format)?:
        return SwiftTypeRep(type(of: format).SwiftType.self)
    }
}
