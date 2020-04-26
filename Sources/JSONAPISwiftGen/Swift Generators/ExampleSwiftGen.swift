//
//  ExampleSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/18/19.
//

import Foundation
import struct OpenAPIKit.AnyCodable
import JSONAPI

/// A Generator that produces Swift code defining an OpenAPI example
/// request/response body as a constant `Data`.
public struct ExampleSwiftGen: SwiftGenerator {
    public let decls: [Decl]

    private let exampleAsDataSwiftString: String

    /// Produces the value of the given Type instead of `Data`
    /// by attempting to parse the JSON of the example as that
    /// type.
    public func valueParsed(as type: SwiftTypeRep) -> Value {
        return Value(value: "JSONDecoder().decode(\(type.swiftCode), from: \(exampleAsDataSwiftString))")
    }

    /// Create an ExampleSwiftGen from the  given codable.
    /// - parameters:
    ///     - openAPIExample: The example taken from a parsed OpenAPI document.
    ///     - propertyName: The name of the constant the generated Swift code should
    ///         produce.
    public init(openAPIExample: AnyCodable, propertyName: String) throws {
        let encoder = JSONEncoder()
        let exampleData = try encoder.encode(openAPIExample)
        guard let exampleString = String(data: exampleData, encoding: .utf8) else {
            throw Error.failureTurningExampleIntoString
        }

        guard exampleString.data(using: .utf8) != nil else {
            throw Error.failureParsingExampleAsUTF8
        }

        exampleAsDataSwiftString = "###\"\(exampleString)\"###.data(using: .utf8)!"

        let decl = StaticDecl(PropDecl.var(propName: propertyName,
                                swiftType: .rep(Data.self),
                                DynamicValue(value: exampleAsDataSwiftString)))

        decls = [decl]
    }

    public enum Error: Swift.Error {
        case failureTurningExampleIntoString
        case failureParsingExampleAsUTF8
    }
}
