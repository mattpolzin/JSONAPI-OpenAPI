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

/// A Generator that produces Swift code defining a function that
/// takes all arguments required to construct a test request and
/// assert the expected response is returned.
///
/// - Important: You must also expose the `testFuncDecl`
///     included as a static var on this type somewhere it is
///     accessible. It is called from the function generated by this
///     type.
public struct APIRequestTestSwiftGen: SwiftGenerator {
    public let decls: [Decl]

    public static var testFuncDecl: Decl { makeTestRequestFunc }

    public init(server: OpenAPI.Server,
                pathComponents: OpenAPI.PathComponents,
                parameters: [OpenAPI.PathItem.Parameter]) throws {

        let parameterArgs = try parameters.map(APIRequestTestSwiftGen.argument)

        let requestBodyTypeDef = SwiftTypeDef(name: "RequestBody", specializationReps: [])
        let responseBodyTypeDef = SwiftTypeDef(name: "ResponseBody", specializationReps: [])

        let allArgs = [
            (name: "requestBody", type: .def(requestBodyTypeDef)),
            (name: "expectedResponseBody", type: .def(responseBodyTypeDef)),
            (name: "expectedResponseStatusCode", type: .init(Int?.self))
        ] + parameterArgs

        // might be a clever way to deal with this, for now just avoid the
        // code that cannot be compiled due to duplicate argument names
        guard Set(allArgs.map { $0.name }).count == allArgs.count else {
            throw Error.duplicateFunctionArgumentDetected
        }

        let specializations = [
            SwiftTypeDef(name: "RequestBody", specializationReps: []),
            SwiftTypeDef(name: "ResponseBody", specializationReps: [])
        ]

        let conditions = [
            (type: specializations[0], conformance: "Encodable"),
            (type: specializations[1], conformance: "Decodable & Equatable")
        ]

        let headers = Value.array(elements: parameters
            .filter {
                $0.parameterLocation == .header(required: true)
                    || $0.parameterLocation == .header(required: false) }
            .map {
                Value.tuple(elements: [
                    (name: "name",
                     value: "\"\($0.name)\""),
                    (name: "value",
                     value: "\(propertyCased($0.name))")
                ])
        })

        let functionDecl = Function(scoping: .init(static: true, privacy: .internal),
                                    name: "test_request",
                                    specializations: specializations,
                                    arguments: allArgs,
                                    conditions: conditions,
                                    body: [
                                        APIRequestTestSwiftGen.urlSnippet(from: pathComponents,
                                                                          originatingAt: server),
                                        PropDecl.let(propName: "headers",
                                                     swiftType: .def(.init(name: "[(name: String, value: String)]")),
                                                     headers),
                                        APIRequestTestSwiftGen.requestFuncCallSnippet
        ])

        decls = [
            functionDecl
        ]
    }

    static var requestFuncCallSnippet: Decl {
        return """

            makeTestRequest(requestBody: requestBody,
                                         expectedResponseBody: expectedResponseBody,
                                         expectedResponseStatusCode: expectedResponseStatusCode,
                                         requestUrl: requestUrl,
                                         headers: headers)
            """ as LiteralSwiftCode
    }

    static func urlSnippet(from path: OpenAPI.PathComponents,
                           originatingAt server: OpenAPI.Server) -> Decl {

        let host = server.url

        return urlSnippet(from: path, originatingAt: host)
    }

    static func urlSnippet(from path: OpenAPI.PathComponents,
                           originatingAt hostUrl: URL) -> Decl {
        let pathString = path.components.map { component in
            guard component.first == "{",
                component.last == "}" else {
                    return component
            }
            return "\\("
                + propertyCased(String(component.dropFirst().dropLast()))
                + ")"
        }.joined(separator: "/")

        return PropDecl.let(propName: "requestUrl",
                            swiftType: .rep(URL.self),
                            .init(value: "URL(string: \"\(hostUrl.absoluteString)/\(pathString)\")!"))
    }

    private static func parameterSnippet(from parameter: OpenAPI.PathItem.Parameter) throws -> Decl {
        let (parameterName, parameterType) = try argument(for: parameter)

        return PropDecl.let(propName: parameterName,
                            swiftType: parameterType,
                            .placeholder(name: parameter.name, type: parameterType))
    }

    static func argument(for parameter: OpenAPI.PathItem.Parameter) throws -> (name: String, type: SwiftTypeRep) {
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

    public enum Error: Swift.Error {
        case parameterContentMapNotSupported
        case parameterSchemaByReferenceNotSupported
        case unsupportedParameterSchema

        case duplicateFunctionArgumentDetected
    }
}

private let makeTestRequestFunc = """

func makeTestRequest<RequestBody, ResponseBody>(requestBody: RequestBody,
                                                expectedResponseBody: ResponseBody,
                                                expectedResponseStatusCode: Int? = nil,
                                                requestUrl: URL,
                                                headers: [(name: String, value: String)]) where RequestBody: Encodable, ResponseBody: Decodable & Equatable {
    var request: URLRequest = URLRequest(url: requestUrl)

    for header in headers {
        request.setValue(header.value, forHTTPHeaderField: header.name)
    }

    let completionExpectation = XCTestExpectation()

    let taskCompletion = { (data: Data?, response: URLResponse?, error: Error?) in
        XCTAssertNil(error)
        XCTAssertNotNil(data)

        if let expectedStatusCode = expectedResponseStatusCode {
            let actualCode = (response as? HTTPURLResponse)?.statusCode
            XCTAssertEqual(actualCode, expectedStatusCode)
        }

        let decoder = JSONDecoder()

        let document: ResponseBody
        do {
            guard let decodedDocument = try data.map({ try decoder.decode(ResponseBody.self, from: $0) }) else {
                XCTFail("Failed to retrieve data from API")
                return
            }
            document = decodedDocument
        } catch let err {
            print("HTTP Status Code: \\((response as? HTTPURLResponse).map { String($0.statusCode) } ?? "N/A")")
            print("Data from API: \\(data.map { String(data: $0, encoding: .utf8)! } ?? "N/A")")
            XCTFail(String(describing: err))
            return
        }

        XCTAssertEqual(document, expectedResponseBody)

        completionExpectation.fulfill()
    }

    let task = URLSession.shared.dataTask(with: request, completionHandler: taskCompletion)
    task.resume()

    XCTWaiter().wait(for: [completionExpectation], timeout: 5)
}
""" as LiteralSwiftCode
