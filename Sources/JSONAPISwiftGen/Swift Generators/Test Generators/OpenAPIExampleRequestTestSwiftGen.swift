//
//  OpenAPIExampleRequestTestSwiftGen.swift
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

    /// Create a generator that creates Swift code for a test that makes an API request and
    ///  checks that the response parses as the documented schema and that the response
    ///  data matches the example data specified.
    /// - parameters:
    ///     - exampleResponseDataPropName: If `nil`, no example data will be compared to the response data for the test.
    ///         If specified, must be the name of a property containing `Data` that will be compared to the response data.
    ///
    public init(server: OpenAPI.Server,
                pathComponents: OpenAPI.Path,
                parameters: [OpenAPI.PathItem.Parameter],
                testProperties: TestProperties,
                exampleResponseDataPropName: String?,
                responseBodyType: SwiftTypeRep,
                expectedHttpStatus: OpenAPI.Response.StatusCode) throws {

        let pathParamDecls: [PropDecl] = try parameters
            .filter { $0.parameterLocation == .path }
            .map { param in
            let (propertyName, propertyType) = try APIRequestTestSwiftGen.argument(for: param)
                guard let propertyValue = testProperties.parameters[param.name] else {
                    throw Error.valueMissingForParameter(named: propertyName, inTest: testProperties.name)
            }

            return PropDecl.let(propName: propertyName,
                                swiftType: propertyType,
                                Value(value: "\"\(propertyValue)\""))
        }

        let requestUrlDecl = APIRequestTestSwiftGen.urlSnippet(from: pathComponents,
                                                               originatingAt: testProperties.host)

        let headersDecl = try OpenAPIExampleRequestTestSwiftGen.headersSnippet(from: parameters,
                                                                               values: testProperties.parameters,
                                                                               inTest: testProperties.name)

        let requestBodyDecl = PropDecl.let(propName: "requestBody",
                                           swiftType: .rep(String.self),
                                           "\"\"")

        let responseBodyDecl = Self.expectedResponseBodySnippet(responseBodyType: responseBodyType,
                                                                exampleResponseDataPropName: testProperties.skipExample ? nil : exampleResponseDataPropName)

        let statusCodeDecl = PropDecl.let(propName: "expectedResponseStatusCode",
                                          swiftType: .init(Int?.self),
                                          Value(value: Int(expectedHttpStatus.rawValue).map(String.init) ?? "nil"))

        let queryParamsValue = Value.array(elements: testProperties.queryParameters.map { (name, value) in
            return Value.tuple(elements: [
                (name: "name",
                 value: "\"\(name)\""),
                (name: "value",
                 value: "\"\(value)\"")
            ])
        }, compacted: true)

        let queryParamsDecl = PropDecl.let(propName: "queryParams",
                                           swiftType: .def(.init(name: "[(name: String, value: String)]")),
                                           queryParamsValue)

        functionName = "_test_example_request_\(safeForPropertyName(testProperties.name))__\(expectedHttpStatus.rawValue)"

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
                                        queryParamsDecl,
                                        APIRequestTestSwiftGen.requestFuncCallSnippet
        ])

        decls = [
            functionDecl
        ]
    }

    static func expectedResponseBodySnippet(responseBodyType: SwiftTypeRep, exampleResponseDataPropName: String?) -> Decl {
        let value = Value(value:
            exampleResponseDataPropName
                .map { "testDecodable(\(responseBodyType.swiftCode).self, from: \($0))" }
                ?? "nil"
        )
        return PropDecl.let(propName: "expectedResponseBody",
                            swiftType: responseBodyType.optional,
                            value)
    }

    static func hostSnippet(from server: OpenAPI.Server) -> Decl {
        let hostUrl = server.url
        return PropDecl.let(propName: "defaultHost",
                            swiftType: .rep(String.self),
                            Value(value: hostUrl.absoluteString))
    }

    static func headersSnippet(from parameters: [OpenAPI.PathItem.Parameter], values: OpenAPI.PathItem.Parameter.ValueMap, inTest testName: String) throws -> Decl {

        let headers = try Value.array(elements: parameters
            .filter {
                $0.parameterLocation == .header(required: true)
                    || $0.parameterLocation == .header(required: false) }
            .map { param in
                guard let parameterValue = values[param.name] else {
                    throw Error.valueMissingForParameter(named: param.name, inTest: testName)
                }

                return Value.tuple(elements: [
                    (name: "name",
                     value: "\"\(param.name)\""),
                    (name: "value",
                     value: "\"\(parameterValue)\"")
                ])
        }, compacted: true)

        return PropDecl.let(propName: "headers",
                            swiftType: .def(.init(name: "[(name: String, value: String)]")),
                            headers)
    }

    public enum Error: Swift.Error, CustomDebugStringConvertible {
        case valueMissingForParameter(named: String, inTest: String)

        public var debugDescription: String {
            switch self {
            case .valueMissingForParameter(named: let name, inTest: let testName):
                return "x-tests/'\(testName)'/parameters was missing a value for the parameter named \(name)."
            }
        }
    }
}

extension OpenAPIExampleRequestTestSwiftGen {

    public struct TestProperties {
        let name: String
        let host: URL
        let skipExample: Bool
        let parameters: OpenAPI.PathItem.Parameter.ValueMap
        let queryParameters: OpenAPI.PathItem.Parameter.ValueMap

        /// Create properties for an API Test
        ///
        /// - parameters:
        ///     - name: The name of the test. This can be anything descriptive.
        ///     - server: The server to run the test against.
        ///     - props: The properties defining the test.
        public init(name: String, server: OpenAPI.Server, props testProps: [String: Any]) throws {

            self.name = name

            let hostParam = testProps["test_host"]
                .flatMap { $0 as? String }
            host =  try hostParam
                .flatMap { try Self.hostOverride(from: $0, inTest: name) }
                ?? server.url

            skipExample = testProps["skip_example"]
                .flatMap { $0 as? Bool }
                ?? false

            guard let testParams = testProps["parameters"] as? OpenAPI.PathItem.Parameter.ValueMap else {
                throw Error.invalidTestParameters(inTest: name)
            }
            parameters = testParams

            guard let queryParamEntries = testProps["query_parameters"] else {
                queryParameters = [:]
                return
            }

            guard let queryParmAnyArray = queryParamEntries as? [[String: String]] else {
                throw Error.queryParamsNotArray(inTest: name)
            }

            let queryParamArray: [(String, String)] = try queryParmAnyArray
                .map {
                    guard let paramName = $0["name"] else {
                        throw Error.queryParamMissingName(inTest: name)
                    }
                    guard let paramValue = $0["value"] else {
                        throw Error.queryParamMissingValue(inTest: name)
                    }
                    return (paramName, paramValue)
            }
            queryParameters = Dictionary(queryParamArray, uniquingKeysWith: { $1 })
        }

        /// Create properties for each test described by the given test dictionary.
        /// This dictionary should have the form:
        ///
        /// ```
        /// {
        ///     "test_name": {
        ///         "test_host": "url", (optional, if omitted then default server for API will be used.
        ///         "skip_example": true | false, (optional, defaults to false)
        ///         "parameters": {
        ///             "path_param_name": "value",
        ///             "header_param_name": "value" (must be a string, even if the parameter type is Int or other)
        ///         },
        ///         "query_parameters": {
        ///             {
        ///                 "name": "param_name",
        ///                 "value": "param_value"
        ///             }
        ///         }
        ///     }
        /// }
        /// ```
        public static func properties(for tests: [String: Any], server: OpenAPI.Server) throws -> [TestProperties] {
            return try tests.map { (name, props) in
                guard let testProps = props as? [String: Any] else {
                    throw Error.invalidTestProperties(inTest: name)
                }

                return try TestProperties(name: name, server: server, props: testProps)
            }
        }

        static func hostOverride(from hostOverrideParameter: String, inTest testName: String) throws -> URL? {
            guard let hostOverrideUrl = URL(string: hostOverrideParameter),
                hostOverrideUrl.host != nil else {
                    throw Error.malformedTestHostUrl(value: hostOverrideParameter, inTest: testName)
            }
            guard hostOverrideUrl.scheme != nil else {
                throw Error.testHostUrlMustContainScheme(inTest: testName)
            }
            return hostOverrideUrl
        }

        public enum Error: Swift.Error, CustomDebugStringConvertible {
            case invalidTestProperties(inTest: String)
            case invalidTestParameters(inTest: String)
            case malformedTestHostUrl(value: String, inTest: String)
            case testHostUrlMustContainScheme(inTest: String)
            case queryParamsNotArray(inTest: String)
            case queryParamMissingName(inTest: String)
            case queryParamMissingValue(inTest: String)

            public var debugDescription: String {
                switch self {
                case .invalidTestProperties(inTest: let testName):
                    return "x-tests/'\(testName)' be a dictionary with String keys."
                case .invalidTestParameters(inTest: let testName):
                    return "x-tests/'\(testName)'/parameters needs to contain only String key/value pairs."
                case .malformedTestHostUrl(value: let urlString, inTest: let testName):
                    return "x-tests/'\(testName)' contained a test host URL that could not be parsed as a URL. The string value is '\(urlString)'."
                case .testHostUrlMustContainScheme(inTest: let testName):
                    return "x-tests/'\(testName)' contained a test host URL that did not specify a scheme. Please include one of 'https', 'http', etc."
                case .queryParamsNotArray(inTest: let testName):
                    return "x-tests/'\(testName)'/query_parameters must be an array of {'name': string, 'value': string} objects."
                case .queryParamMissingName(inTest: let testName):
                    return "x-tests/'\(testName)'/query_parameters contained an entry with no 'name'."
                case .queryParamMissingValue(inTest: let testName):
                    return "x-tests/'\(testName)'/query_parameters contained an entry with no 'value'."
                }
            }
        }
    }
}
