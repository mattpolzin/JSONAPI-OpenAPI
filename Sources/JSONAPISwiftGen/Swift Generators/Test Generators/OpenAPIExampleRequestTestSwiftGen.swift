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

        let hostOverride: URL?
        if let hostOverrideParameter = parameterValues["test_host"] {
            guard let hostOverrideUrl = URL(string: hostOverrideParameter),
                hostOverrideUrl.host != nil else {
                throw Error.malformedTestHostUrl(value: hostOverrideParameter)
            }
            guard hostOverrideUrl.scheme != nil else {
                throw Error.testHostUrlMustContainScheme
            }
            hostOverride = hostOverrideUrl
        } else {
            hostOverride = nil
        }

        let requestUrlDecl = APIRequestTestSwiftGen.urlSnippet(from: pathComponents,
                                                               originatingAt: hostOverride ?? server.url)

        let headersDecl = try OpenAPIExampleRequestTestSwiftGen.headersSnippet(from: parameters, values: parameterValues)

        let requestBodyDecl = PropDecl.let(propName: "requestBody",
                                           swiftType: .rep(String.self),
                                           "\"\"")

        let responseBodyDecl = PropDecl.let(propName: "expectedResponseBody",
                                            swiftType: responseBodyType.optional,
                                            Value(value: "testDecodable(\(responseBodyType.swiftCode).self, from: \(exampleResponseDataPropName))"))

        let statusCodeDecl = PropDecl.let(propName: "expectedResponseStatusCode",
                                          swiftType: .init(Int?.self),
                                          Value(value: Int(expectedHttpStatus.rawValue).map(String.init) ?? "nil"))

        functionName = "_test_example_request__\(expectedHttpStatus.rawValue)"

        let functionDecl = Function(scoping: .init(static: true, privacy: .internal),
                                    name: functionName,
                                    specializations: nil,
                                    arguments: [],
                                    conditions: nil,
                                    body: pathParamDecls + [
                                        requestUrlDecl,
                                        headersDecl,
                                        requestBodyDecl,
                                        responseBodyDecl,
                                        statusCodeDecl,
                                        APIRequestTestSwiftGen.requestFuncCallSnippet
        ])

        decls = [
            functionDecl
        ]
    }

    static func hostSnippet(from server: OpenAPI.Server) -> Decl {
        let hostUrl = server.url
        return PropDecl.let(propName: "defaultHost",
                            swiftType: .rep(String.self),
                            Value(value: hostUrl.absoluteString))
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

    public enum Error: Swift.Error, CustomDebugStringConvertible {
        case valueMissingForParameter(named: String)
        case malformedTestHostUrl(value: String)
        case testHostUrlMustContainScheme

        public var debugDescription: String {
            switch self {
            case .valueMissingForParameter(named: let name):
                return "x-testParameters was missing a value for the parameter named \(name)."
            case .malformedTestHostUrl(value: let urlString):
                return "x-testParameters contained a test host URL that could not be parsed as a URL. The string value is '\(urlString)'."
            case .testHostUrlMustContainScheme:
                return "x-testParameters contained a test host URL that did not specify a scheme. Please include one of 'https', 'http', etc."
            }
        }
    }
}
