//
//  OpenAPIExampleRequestTestSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/18/19.
//

import Foundation
import OpenAPIKit

public extension OpenAPI.Parameter {
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
    public init(
        server: OpenAPI.Server,
        pathComponents: OpenAPI.Path,
        parameters: [OpenAPI.Parameter],
        testSuiteConfiguration: TestSuiteConfiguration,
        testProperties: TestProperties,
        exampleResponseDataPropName: String?,
        responseBodyType: SwiftTypeRep,
        expectedHttpStatus: OpenAPI.Response.StatusCode
    ) throws {

        let pathParamDecls: [PropDecl] = try parameters
            .filter { $0.location == .path }
            .map { parameter in
                let (propertyName, _) = try APIRequestTestSwiftGen.argument(for: parameter)

                // always use string type here for path components. this is how the path components
                // are required to be specifed (as strings) in the `x-tests` OpenAPI extension.
                let propertyType = SwiftTypeRep(String.self)

                guard let propertyValue = testProperties.parameters[parameter.name] else {
                    // we can't _not_ throw the following error because if a path parameter is missing
                    // then we cannot even build the URL for the request. However, if ignoring missing
                    // parameters is enabled, then this error will not be tracked as a warning.
                    throw Error.valueMissingForParameter(named: parameter.name, inTest: testProperties.name)
                }

                return PropDecl.let(
                    propName: propertyName,
                    swiftType: propertyType,
                    Value(value: "\"\(propertyValue)\"")
                )
        }

        let requestUrlDecl = APIRequestTestSwiftGen.urlSnippet(
            from: pathComponents,
            originatingAt: testSuiteConfiguration.apiHostOverride ?? testProperties.host
        )

        let headersDecl = try OpenAPIExampleRequestTestSwiftGen.headersSnippet(
            from: parameters,
            values: testProperties.parameters,
            inTest: testProperties.name,
            reportingMissingParameters: !testProperties.ignoreMissingParameterWarnings
        )

        let requestBodyDecl = PropDecl.let(
            propName: "requestBody",
            swiftType: .rep(String.self),
            "\"\""
        )

        let responseBodyDecl = Self.expectedResponseBodySnippet(
            responseBodyType: responseBodyType,
            exampleResponseDataPropName: testProperties.skipExample ? nil : exampleResponseDataPropName
        )

        let statusCodeDecl = PropDecl.let(
            propName: "expectedResponseStatusCode",
            swiftType: .init(Int?.self),
            Value(value: Int(expectedHttpStatus.rawValue).map(String.init) ?? "nil")
        )

        let queryParamsValue = Value.array(elements: testProperties.queryParameters.map { (name, value) in
            return Value.tuple(elements: [
                (name: "name",
                 value: "\"\(name)\""),
                (name: "value",
                 value: "\"\(value)\"")
            ])
        }, compacted: true)

        let queryParamsDecl = PropDecl.let(
            propName: "queryParams",
            swiftType: .def(.init(name: "[(name: String, value: String)]")),
            queryParamsValue
        )

        functionName = "_test_example_request_\(safeForPropertyName(testProperties.name))__\(expectedHttpStatus.rawValue)"

        let functionDecl = Function(
            scoping: .init(static: true, privacy: .internal),
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
            ]
        )

        decls = [
            functionDecl
        ]
    }

    static func expectedResponseBodySnippet(
        responseBodyType: SwiftTypeRep,
        exampleResponseDataPropName: String?
    ) -> Decl {
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

    static func headersSnippet(
        from parameters: [OpenAPI.Parameter],
        values: OpenAPI.Parameter.ValueMap,
        inTest testName: String,
        reportingMissingParameters: Bool
    ) throws -> Decl {

        struct HeaderOption: Hashable {
            let name: String
            let required: Bool
        }

        let knownHeaders = [
            "Session-Token",
            "Authorization",
            "Content-Type",
            "User-Agent"
        ].map { HeaderOption(name: $0, required: false) }

        let parameterHeaders = parameters.filter { $0.context.inHeader }
            .map { HeaderOption(name: $0.name, required: $0.required) }

        let allHeaders = Set(parameterHeaders + knownHeaders)

        let headers = try Value.array(
            elements: allHeaders
                .compactMap { header in
                    guard let parameterValue = values[header.name] else {
                        if header.required && reportingMissingParameters {
                            throw Error.valueMissingForParameter(named: header.name, inTest: testName)
                        }
                        return nil
                    }

                    return Value.tuple(elements: [
                        (name: "name",
                         value: "\"\(header.name)\""),
                        (name: "value",
                         value: "\"\(parameterValue)\"")
                    ])
            },
            compacted: true
        )

        return PropDecl.let(
            propName: "headers",
            swiftType: .def(.init(name: "[(name: String, value: String)]")),
            headers
        )
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
