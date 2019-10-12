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

        let parameterArgs = try parameters
            .filter { !$0.parameterLocation.isQuery } // for now these are handled as a block rather than each as separate args
            .map(APIRequestTestSwiftGen.argument)

        let requestBodyTypeDef = SwiftTypeDef(name: "RequestBody", specializationReps: [])
        let responseBodyTypeDef = SwiftTypeDef(name: "ResponseBody", specializationReps: [])

        let allArgs = [
            (name: "requestBody", type: .def(requestBodyTypeDef)),
            (name: "expectedResponseBody", type: .def(responseBodyTypeDef)),
            (name: "expectedResponseStatusCode", type: .init(Int?.self))
        ] + parameterArgs + [
            (name: "queryParams", type: .def(.init(name: "[(name: String, value: String)]")))
        ]

        // might be a clever way to deal with this, for now just avoid the
        // code that cannot be compiled due to duplicate argument names
        guard Set(allArgs.map { $0.name }).count == allArgs.count else {
            throw Error.duplicateFunctionArgumentDetected
        }

        let genericTypes = (
            SwiftTypeDef(name: "RequestBody", specializationReps: []),
            SwiftTypeDef(name: "ResponseBody", specializationReps: [])
        )

        let specializations = [
            genericTypes.0,
            genericTypes.1
        ]

        let conditions = [
            (type: genericTypes.0, conformance: "Encodable"),
            (type: genericTypes.1, conformance: "Decodable & Equatable")
        ]

        let headersValue = Value.array(elements: parameters
            .filter { $0.parameterLocation.isHeader }
            .map {
                let headerVal = Value.tuple(elements: [
                    (name: "name",
                     value: "\"\($0.name)\""),
                    (name: "value",
                     value: "\(propertyCased($0.name))")
                ])

                guard !$0.required else {
                    return headerVal
                }

                return Value(value: "\(propertyCased($0.name)).map { \(propertyCased($0.name)) in \(headerVal.value) }")
        }, compacted: true)

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
                                                     headersValue),
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
                                         headers: headers,
                                         queryParams: queryParams)
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
        let isParamRequired = parameter.required
        let parameterType = try type(from: parameter.schemaOrContent)

        return (name: parameterName, type: isParamRequired ? parameterType : parameterType.optional)
    }

    private static func type(from parameterSchemaOrContent: Either<OpenAPI.PathItem.Parameter.SchemaProperty, OpenAPI.Content.Map>) throws -> SwiftTypeRep {
        switch parameterSchemaOrContent {
        case .a(.b(let schema)):
            do {

                return try swiftType(from: schema,
                                     allowPlaceholders: false,
                                     handleOptionality: false)
            } catch {
                throw Error.unsupportedParameterSchema
            }
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
                                                expectedResponseBody optionallyExpectedResponseBody: ResponseBody? = nil,
                                                expectedResponseStatusCode: Int? = nil,
                                                requestUrl: URL,
                                                headers: [(name: String, value: String)],
                                                queryParams: [(name: String, value: String)]) where RequestBody: Encodable, ResponseBody: Decodable & Equatable {
    var urlComponents = URLComponents(url: requestUrl, resolvingAgainstBaseURL: false)!

    urlComponents.queryItems = queryParams
        .map {
            URLQueryItem(name: $0.name, value: $0.value)
    }

    var request: URLRequest = URLRequest(url: urlComponents.url!)

    for header in headers {
        request.setValue(header.value, forHTTPHeaderField: header.name)
    }

    let completionExpectation = XCTestExpectation()

    let taskCompletion = { (data: Data?, response: URLResponse?, error: Error?) in
        XCTAssertNil(error)
        XCTAssertNotNil(data)

        if let expectedStatusCode = expectedResponseStatusCode {
            let actualCode = (response as? HTTPURLResponse)?.statusCode
            XCTAssertEqual(actualCode, expectedStatusCode, "The response HTTP status code did not match the expected status code.")
        }

        let decoder = JSONDecoder()

        let document: ResponseBody
        do {
            guard let decodedDocument = try data.map({ try decoder.decode(ResponseBody.self, from: $0) }) else {
                XCTFail("Failed to retrieve data from API.")
                return
            }
            document = decodedDocument
        } catch let err {
            XCTFail("Failed to parse response: " + String(describing: err))
            return
        }

        if let expectedResponseBody = optionallyExpectedResponseBody {
            XCTAssertEqual(document, expectedResponseBody, "The response body did not match the expected response body.")
        }

        completionExpectation.fulfill()
    }

    let task = URLSession.shared.dataTask(with: request, completionHandler: taskCompletion)
    task.resume()

    XCTWaiter().wait(for: [completionExpectation], timeout: 5)
}
""" as LiteralSwiftCode
