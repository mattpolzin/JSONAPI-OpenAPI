//
//  TestSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/18/19.
//

import Foundation
import OpenAPIKit

public extension OpenAPI.PathItem.Parameter {
    /// Map from a Parameter's name to that Parameter's string-encoded value
    typealias ValueMap = [String: String]
}

/// A Generator that produces Swift code defining a test function
/// based on a provided OpenAPI example and some API parameters.
public struct OpenAPIExampleRequestTestSwiftGen: SwiftFunctionGenerator {
    public let decls: [Decl]
    public let functionName: String

    public init(server: OpenAPI.Server,
                pathComponents: OpenAPI.PathComponents,
                parameters: [OpenAPI.PathItem.Parameter],
                parameterValues: OpenAPI.PathItem.Parameter.ValueMap,
                exampleResponseDataPropName: String,
                responseBodyType: SwiftTypeRep,
                expectedHttpStatus: OpenAPI.Response.StatusCode) throws {

        // TODO: assert status code as expected in generated test function

        let pathParamDecls: [PropDecl] = try parameters
            .filter { $0.parameterLocation == .path }
            .map { param in
            let (propertyName, propertyType) = try APIRequestTestSwiftGen.argument(for: param)
            guard let propertyValue = parameterValues[param.name] else {
                throw Error.valueMissingForParameter(named: propertyName)
            }

            return PropDecl.let(propName: propertyName,
                                swiftType: propertyType,
                                Value(value: "\"\(propertyValue)\""))
        }

        let requestUrlDecl = APIRequestTestSwiftGen.urlSnippet(from: pathComponents,
                                                               originatingAt: server)

        let headersDecl = try OpenAPIExampleRequestTestSwiftGen.headersSnippet(from: parameters, values: parameterValues)

        let requestBodyDecl = PropDecl.let(propName: "requestBody",
                                           swiftType: .rep(String.self),
                                           "\"\"")

        let responseBodyTryDecl = PropDecl.let(propName: "expectedResponseBody",
                                            swiftType: responseBodyType,
                                            Value(value: "try JSONDecoder().decode(\(responseBodyType.swiftCode).self, from: \(exampleResponseDataPropName))"))

        let doCatchBlock = DoCatchBlock(body: [ requestBodyDecl,
                                                responseBodyTryDecl,
                                                APIRequestTestSwiftGen.requestFuncCallSnippet ],
                                        errorName: "error",
                                        catchBody: [ OpenAPIExampleParseTestSwiftGen.catchBodyDecl ])

        functionName = "test_example_request__\(expectedHttpStatus.rawValue)"

        let functionDecl = Function(scoping: .init(static: true, privacy: .internal),
                                    name: functionName,
                                    specializations: nil,
                                    arguments: [],
                                    conditions: nil,
                                    body: pathParamDecls + [
                                        requestUrlDecl,
                                        headersDecl,
                                        doCatchBlock
        ])

        decls = [
            functionDecl
        ]
    }

    static func headersSnippet(from parameters: [OpenAPI.PathItem.Parameter], values: OpenAPI.PathItem.Parameter.ValueMap) throws -> Decl {

        let headers = try Value.array(elements: parameters
            .filter {
                $0.parameterLocation == .header(required: true)
                    || $0.parameterLocation == .header(required: false) }
            .map { param in
                guard let parameterValue = values[param.name] else {
                    throw Error.valueMissingForParameter(named: param.name)
                }

                return Value.tuple(elements: [
                    (name: "name",
                     value: "\"\(param.name)\""),
                    (name: "value",
                     value: "\"\(parameterValue)\"")
                ])
        })

        return PropDecl.let(propName: "headers",
                            swiftType: .def(.init(name: "[(name: String, value: String)]")),
                            headers)
    }

    enum Error: Swift.Error {
        case valueMissingForParameter(named: String)
    }
}
