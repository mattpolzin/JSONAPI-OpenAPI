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
///
/// - Important: You must also expose the `testFuncDecl`
///     included as a static var on this type somewhere it is
///     accessible. It is called from the function generated by this
///     type.
public struct OpenAPIExampleParseTestSwiftGen: SwiftFunctionGenerator {
    public let decls: [Decl]
    public let functionName: String

    public static var testFuncDecl: Decl { makeTestFuncDecl }

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

        let responseBodyDecl = PropDecl.let(propName: "_",
                                            swiftType: bodyType.optional,
                                            Value(value: "testDecodable(\(bodyType.swiftCode).self, from: \(exampleDataPropName))"))

        let statusCodeNameSuffix = exampleHttpStatusCode.map { "__\($0.rawValue)" } ?? ""

        functionName = "_test_example_parse\(statusCodeNameSuffix)"

        let functionDecl = Function(scoping: .init(static: true, privacy: .internal),
                                    name: functionName,
                                    specializations: nil,
                                    arguments: [],
                                    conditions: nil,
                                    body: [ responseBodyDecl ])

        decls = [
            functionDecl
        ]
    }
}

private let makeTestFuncDecl: Decl = """
public func testDecodable<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
    do {
        return try JSONDecoder().decode(type, from: data)
    } catch let error {
        guard let err = error as? DecodingError else {
            XCTFail(String(describing: error))
            return nil
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
        return nil
    }
}
""" as LiteralSwiftCode
