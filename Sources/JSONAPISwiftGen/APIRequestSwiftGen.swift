//
//  ResourceObjectStubSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/8/19.
//

import Foundation
import OpenAPIKit
import JSONAPI
import Poly

public struct APIRequestSwiftGen: SwiftGenerator {
    public let decls: [Decl]
    public let swiftCode: String

    public init(server: OpenAPI.Server,
                pathComponents: OpenAPI.PathComponents,
                parameters: [OpenAPI.PathItem.Parameter]) throws {

        let parameterArgs = try parameters.map(APIRequestSwiftGen.argument)

        let requestBodyTypeDef = SwiftTypeDef(name: "RequestBody", specializationReps: [])
        let responseBodyTypeDef = SwiftTypeDef(name: "ResponseBody", specializationReps: [])

        let allArgs = [
            (name: "requestBody", type: .def(requestBodyTypeDef)),
            (name: "expectedResponseBody", type: .def(responseBodyTypeDef))
        ] + parameterArgs

        let specializations = [
            SwiftTypeDef(name: "RequestBody", specializationReps: []),
            SwiftTypeDef(name: "ResponseBody", specializationReps: [])
        ]

        let conditions = [
            (type: specializations[0], conformance: "Encodable"),
            (type: specializations[1], conformance: "Decodable & Equatable")
        ]

        let headers = Value.array(elements:parameters
            .filter {
                $0.parameterLocation == .header(required: true)
                    || $0.parameterLocation == .header(required: false) }
            .map {
                Value.tuple(elements: [
                    (name: "name",
                     value: "\"\($0.name)\""),
                    (name: "value",
                     value: "\(APIRequestSwiftGen.propertyCased($0.name))")
                ])
        })

        let functionDecl = Function(scoping: .init(static: true, privacy: .internal),
                                    name: "test_request",
                                    specializations: specializations,
                                    arguments: allArgs,
                                    conditions: conditions,
                                    body: [
                                        APIRequestSwiftGen.urlSnippet(from: pathComponents,
                                                                      originatingAt: server),
                                        PropDecl.var(propName: "request",
                                                     swiftType: .rep(URLRequest.self),
                                                     "URLRequest(url: requestUrl)" as Value),
                                        PropDecl.let(propName: "headers",
                                                     swiftType: .def(.init(name: "[(name: String, value: String)]", specializationReps: [])),
                                                     headers),
"""

for header in headers {
    request.setValue(header.value, forHTTPHeaderField: header.name)
}

let completionExpectation = XCTestExpectation()

let taskCompletion = { (data: Data?, response: URLResponse?, error: Error?) in
    XCTAssertNil(error)
    XCTAssertNotNil(data)

    let decoder = JSONDecoder()

    guard let document = try! data.map({ try decoder.decode(type(of: expectedResponseBody).self, from: $0) }) else {
        XCTFail("Failed to decode response document")
        return
    }

    XCTAssertEqual(document, expectedResponseBody)

    completionExpectation.fulfill()
}

let task = URLSession.shared.dataTask(with: request, completionHandler: taskCompletion)
task.resume()

XCTWaiter().wait(for: [completionExpectation], timeout: 5)
""" as LiteralSwiftCode
        ])

        decls = [
            functionDecl
        ]
        
        swiftCode = APIRequestSwiftGen.swiftCode(from: decls)
    }

    static func swiftCode(from decls: [Decl]) -> String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
    }

    private static func urlSnippet(from path: OpenAPI.PathComponents,
                                   originatingAt server: OpenAPI.Server) -> Decl {

        let host = server.url

        let pathString = path.components.map { component in
            guard component.first == "{",
                component.last == "}" else {
                    return component
            }
            return "\\("
                + APIRequestSwiftGen.propertyCased(String(component.dropFirst().dropLast()))
                + ")"
        }.joined(separator: "/")

        return PropDecl.let(propName: "requestUrl",
                            swiftType: .rep(URL.self),
                            .init(value: "URL(string: \"\(host.absoluteString)/\(pathString)\")!"))
    }

    private static func parameterSnippet(from parameter: OpenAPI.PathItem.Parameter) throws -> Decl {
        let (parameterName, parameterType) = try argument(for: parameter)

        return PropDecl.let(propName: parameterName,
                            swiftType: parameterType,
                            .placeholder(name: parameter.name, type: parameterType))
    }

    private static func argument(for parameter: OpenAPI.PathItem.Parameter) throws -> (name: String, type: SwiftTypeRep) {
        let parameterName = propertyCased(parameter.name)
        let parameterType = try type(from: parameter.schemaOrContent)

        return (name: parameterName, type: .rep(parameterType))
    }

    private static func type(from parameterSchemaOrContent: Either<OpenAPI.PathItem.Parameter.SchemaProperty, OpenAPI.Content.Map>) throws -> SwiftType.Type {
        switch parameterSchemaOrContent {
        case .a(.b(let schema)):
            guard let paramType = schema.jsonTypeFormat?.swiftType,
                let swiftType = paramType as? SwiftType.Type else {
                throw Error.unsupportedParameterSchema
            }
            return swiftType
        case .b:
            throw Error.parameterContentMapNotSupported
        default:
            throw Error.parameterSchemaByReferenceNotSupported
        }
    }

    private static func propertyCased(_ name: String) -> String {
        let words = name.split(whereSeparator: "_-".contains)
        let first = words.first.map { [String($0).lowercased()] } ?? []
        let casedWords = first + words.dropFirst().map { (word) -> String in
            let firstChar = word.first?.uppercased() ?? ""
            return String(firstChar + word.dropFirst())
        }
        return casedWords.joined()
    }

    public enum Error: Swift.Error {
        case parameterContentMapNotSupported
        case parameterSchemaByReferenceNotSupported
        case unsupportedParameterSchema
    }
}
