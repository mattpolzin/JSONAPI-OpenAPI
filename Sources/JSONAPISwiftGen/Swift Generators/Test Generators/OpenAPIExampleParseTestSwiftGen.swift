//
//  TestSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/18/19.
//

import Foundation
import OpenAPIKit

/// A Generator that produces Swift code defining a test function
/// based on a provided OpenAPI example. It will verify the example
/// parses under the given OpenAPI defintions.
public struct OpenAPIExampleParseTestSwiftGen: SwiftFunctionGenerator {
    public let decls: [Decl]
    public let functionName: String

    /// - parameters:
    ///     - exampleDataPropName: The name of a property available in the current scope.
    ///         This property must contain `Data` to be parsed as the given body type.
    ///     - bodyType: The request/response body type, which must be available in the current scope.
    ///         This type must be Decodable. The given example will be decoded as this type.
    ///     - exampleHttpStatusCode: The status code under which this example lives. This is just
    ///         used to help name the test function.
    public init(exampleDataPropName: String,
                bodyType: SwiftTypeRep,
                exampleHttpStatusCode: OpenAPI.Response.StatusCode?) throws {

        let responseBodyTryDecl = PropDecl.let(propName: "expectedBody",
                                            swiftType: bodyType,
                                            Value(value: "try JSONDecoder().decode(\(bodyType.swiftCode).self, from: \(exampleDataPropName))"))

        let doCatchBlock = DoCatchBlock(body: [ responseBodyTryDecl ],
                                        errorName: "error",
                                        catchBody: [ Self.catchBodyDecl ])

        let statusCodeNameSuffix = exampleHttpStatusCode.map { "__\($0.rawValue)" } ?? ""

        functionName = "_test_example_parse\(statusCodeNameSuffix)"

        let functionDecl = Function(scoping: .init(static: true, privacy: .internal),
                                    name: functionName,
                                    specializations: nil,
                                    arguments: [],
                                    conditions: nil,
                                    body: [ doCatchBlock ])

        decls = [
            functionDecl
        ]
    }

    static let catchBodyDecl: Decl =
"""
    guard let err = error as? DecodingError else {
        XCTFail(String(describing: error))
        return
    }
    func pathString(context: DecodingError.Context) -> String {
        return context.codingPath.map {
            let intIdxString = $0.intValue.map { "[\\($0)]" }
            let namedKeyString = "/\\($0.stringValue)"
            return intIdxString ?? namedKeyString
        }.joined()
    }
    switch err {
    case .keyNotFound(let key, let context):
        let intIdxString = key.intValue.map { "at index \\($0)" }
        let namedKeyString = "named '\\(key.stringValue)'"
        let path = pathString(context: context)
        XCTFail("Missing key \\(intIdxString ?? namedKeyString) at \\(path)")
    case .typeMismatch(let expectedType, let context):
        let expectedTypString = String(describing: expectedType)
        let path = pathString(context: context)
        XCTFail("Did not find expected type (\\(expectedTypString)) at \\(path)")
    case .valueNotFound(let expectedType, let context):
        let expectedTypeString = String(describing: expectedType)
        let path = pathString(context: context)
        XCTFail("Expected to find \\(expectedTypeString) but found null instead at \\(path)")
    default:
        XCTFail(String(describing: err))
    }

    return
""" as LiteralSwiftCode
}
