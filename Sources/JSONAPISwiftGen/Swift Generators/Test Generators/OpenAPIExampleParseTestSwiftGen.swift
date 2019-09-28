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
    ///     - exampleResponseDataPropName: The name of a property available in the current scope.
    ///         This property must contain `Data` to be parsed as the given response body type.
    ///     - responseBodyType: The response body type, which must be available in the current scope.
    ///         This type must be Decodable. The given example response will be decoded as this type.
    ///     - exampleHttpStatusCode: The status code under which this example lives. This is just
    ///         used to help name the test function.
    public init(exampleResponseDataPropName: String,
                responseBodyType: SwiftTypeRep,
                exampleHttpStatusCode: OpenAPI.Response.StatusCode) throws {

        let requestBodyDecl = PropDecl.let(propName: "requestBody",
                                           swiftType: .rep(String.self),
                                           "\"\"")

        let responseBodyTryDecl = PropDecl.let(propName: "expectedResponseBody",
                                            swiftType: responseBodyType.optional,
                                            Value(value: "try JSONDecoder().decode(\(responseBodyType.swiftCode).self, from: \(exampleResponseDataPropName))"))

        let doCatchBlock = DoCatchBlock(body: [ requestBodyDecl,
                                                responseBodyTryDecl ],
                                        errorName: "error",
                                        catchBody: [ "XCTFail(String(describing: error))" as LiteralSwiftCode,
                                                     "return" as LiteralSwiftCode ])

        functionName = "test_example_parse_\(exampleHttpStatusCode.rawValue)"

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
}
