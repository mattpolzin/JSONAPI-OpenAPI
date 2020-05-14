//
//  TestProperties.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 4/25/20.
//

import Foundation
import OpenAPIKit

extension OpenAPIExampleRequestTestSwiftGen {

    public struct TestProperties {
        public let name: String
        public let host: URL
        public let skipExample: Bool
        public let parameters: OpenAPI.Parameter.ValueMap
        public let queryParameters: OpenAPI.Parameter.ValueMap
        public let ignoreMissingParameterWarnings: Bool

        /// Create properties for an API Test
        ///
        /// - parameters:
        ///     - name: The name of the test. This can be anything descriptive.
        ///     - server: The server to run the test against.
        ///     - props: The properties defining the test.
        public init(name: String, server: OpenAPI.Server, props testProps: [String: Any]) throws {

            self.name = name

            ignoreMissingParameterWarnings = (testProps["ignore_missing_parameter_warnings"] as? Bool) ?? false

            let hostParam = testProps["test_host"]
                .flatMap { $0 as? String }
            host =  try hostParam
                .flatMap { try Self.hostOverride(from: $0, inTest: name) }
                ?? server.url

            skipExample = testProps["skip_example"]
                .flatMap { $0 as? Bool }
                ?? false

            guard let testParams = testProps["parameters"] as? OpenAPI.Parameter.ValueMap else {
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
        ///         "ignore_missing_parameter_warnings": true | false, (optional, defaults to false)
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
