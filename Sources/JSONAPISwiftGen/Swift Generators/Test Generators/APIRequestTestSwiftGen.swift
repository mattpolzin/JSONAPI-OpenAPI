//
//  ResourceObjectStubSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/8/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

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

    public init(
        server: OpenAPI.Server,
        pathComponents: OpenAPI.Path,
        parameters: [DereferencedParameter]
    ) throws {

        let parameterArgs = try parameters
            .filter { !$0.context.inQuery } // for now these are handled as a block rather than each as separate args
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
            .filter { $0.context.inHeader }
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

        let headerParamsDecl = PropDecl.let(propName: "headers",
                                            swiftType: .def(.init(name: "[(name: String, value: String)]")),
                                            headersValue)

        let functionDecl = Function(
            scoping: .init(static: true, privacy: .internal),
            name: "test_request",
            specializations: specializations,
            arguments: allArgs,
            conditions: conditions,
            body: [
                APIRequestTestSwiftGen.urlSnippet(
                    from: pathComponents,
                    originatingAt: server
                ),
                headerParamsDecl,
                APIRequestTestSwiftGen.requestFuncCallSnippet
            ]
        )

        decls = [
            functionDecl
        ]
    }

    static var requestFuncCallSnippet: Decl {
        return """

            makeTestRequest(
                requestBody: requestBody,
                expectedResponseBody: expectedResponseBody,
                expectedResponseStatusCode: expectedResponseStatusCode,
                requestUrl: requestUrl,
                headers: headers,
                queryParams: queryParams
            )
            """ as LiteralSwiftCode
    }

    static func urlSnippet(
        from path: OpenAPI.Path,
        originatingAt server: OpenAPI.Server
    ) -> Decl {

        let host = server.url

        return urlSnippet(from: path, originatingAt: host)
    }

    static func urlSnippet(
        from path: OpenAPI.Path,
        originatingAt hostUrl: URL
    ) -> Decl {
        let pathString = path.components.map { component in
            guard component.first == "{",
                component.last == "}" else {
                    return component
            }
            return "\\("
                + propertyCased(String(component.dropFirst().dropLast()))
                + ")"
        }.joined(separator: "/")

        return PropDecl.let(
            propName: "requestUrl",
            swiftType: .rep(URL.self),
            .init(value: "URL(string: \"\(hostUrl.absoluteString)/\(pathString)\")!")
        )
    }

    private static func parameterSnippet(from parameter: DereferencedParameter) throws -> Decl {
        let (parameterName, parameterType) = try argument(for: parameter)

        return PropDecl.let(
            propName: parameterName,
            swiftType: parameterType,
            .placeholder(name: parameter.name, type: parameterType)
        )
    }

    static func argument(for parameter: DereferencedParameter) throws -> (name: String, type: SwiftTypeRep) {
        let parameterName = propertyCased(parameter.name)
        let isParamRequired = parameter.required
        let parameterType = try type(from: parameter.schemaOrContent)

        return (name: parameterName, type: isParamRequired ? parameterType : parameterType.optional)
    }

    private static func type(
        from parameterSchemaOrContent: Either<DereferencedSchemaContext, DereferencedContent.Map>
    ) throws -> SwiftTypeRep {
        switch parameterSchemaOrContent {
        case .a(let paramSchema):
            do {
                return try swiftType(
                    from: paramSchema.schema,
                    allowPlaceholders: false,
                    handleOptionality: false
                )
            } catch {
                throw Error.unsupportedParameterSchema
            }
        case .b:
            throw Error.parameterContentMapNotSupported
        }
    }

    public enum Error: Swift.Error {
        case parameterContentMapNotSupported
        case unsupportedParameterSchema

        case duplicateFunctionArgumentDetected
    }
}

//
// IMPORTANT:
// The following stringified Swift that gets printed
// verbatim to test projects that are generated can be
// found in `APIRequestTestSwiftGenTests.swift` where
// edits should be made and simply copied over to this
// string literal.
//

private let makeTestRequestFunc = #"""

/// Log warning after test case logs
func XCTWarn(_ message: String, at url: URL) {
    print("[\(url.absoluteString)] : warning - \(message)")
}

/// JSONAPI Document Response request test
func makeTestRequest<RequestBody, ResponseBody>(
    requestBody: RequestBody,
    expectedResponseBody optionallyExpectedResponseBody: ResponseBody? = nil,
    expectedResponseStatusCode: Int? = nil,
    requestUrl: URL,
    headers: [(name: String, value: String)],
    queryParams: [(name: String, value: String)],
    function: StaticString = #function
) where RequestBody: Encodable, ResponseBody: CodableJSONAPIDocument, ResponseBody.PrimaryResourceBody: TestableResourceBody, ResponseBody.Body: Equatable {
    let successResponseHandler = { (data: Data) in
        let decoder = JSONDecoder()

        let document: ResponseBody
        do {
            document = try decoder.decode(ResponseBody.self, from: data)
        } catch let err {
            XCTWarn("Failed to parse as JSON:API: \(String(data: data, encoding: .utf8) ?? "")", at: requestUrl)
            XCTFail("Failed to parse response: " + String(describing: err))
            return
        }

        if let expectedResponseBody = optionallyExpectedResponseBody {
            let comparison = document.compare(to: expectedResponseBody)
            XCTAssert(comparison.isSame, comparison.rawValue)
        } else {
            XCTWarn("Not asserting a particular response body is received, only that response can be parsed.", at: requestUrl)
        }
    }

    makeTestRequest(
        requestBody: requestBody,
        successResponseHandler: successResponseHandler,
        expectedResponseStatusCode: expectedResponseStatusCode,
        requestUrl: requestUrl,
        headers: headers,
        queryParams: queryParams,
        function: function
    )
}

/// General purpose request test
func makeTestRequest<RequestBody, ResponseBody>(
    requestBody: RequestBody,
    expectedResponseBody optionallyExpectedResponseBody: ResponseBody? = nil,
    expectedResponseStatusCode: Int? = nil,
    requestUrl: URL,
    headers: [(name: String, value: String)],
    queryParams: [(name: String, value: String)],
    function: StaticString = #function
) where RequestBody: Encodable, ResponseBody: Decodable & Equatable {
    let successResponseHandler = { (data: Data) in
        let decoder = JSONDecoder()

        let document: ResponseBody
        do {
            document = try decoder.decode(ResponseBody.self, from: data)
        } catch let err {
            XCTWarn("Failed to parse: \(String(data: data, encoding: .utf8) ?? "")", at: requestUrl)
            XCTFail("Failed to parse response: " + String(describing: err))
            return
        }

        if let expectedResponseBody = optionallyExpectedResponseBody {
            XCTAssertEqual(document, expectedResponseBody, "Response Body did not match expectation")
        }
    }

    makeTestRequest(
        requestBody: requestBody,
        successResponseHandler: successResponseHandler,
        expectedResponseStatusCode: expectedResponseStatusCode,
        requestUrl: requestUrl,
        headers: headers,
        queryParams: queryParams,
        function: function
    )
}

func makeTestRequest<RequestBody>(
    requestBody: RequestBody,
    successResponseHandler: @escaping (Data) -> Void,
    expectedResponseStatusCode: Int? = nil,
    requestUrl: URL,
    headers: [(name: String, value: String)],
    queryParams: [(name: String, value: String)],
    function: StaticString = #function
) where RequestBody: Encodable {
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
        if let error = error as? URLError {
            let urlString = error.failureURLString.map { " \($0)" } ?? " originally requested: \(requestUrl.absoluteString)"
            XCTFail("\(error.localizedDescription) (\(error.code.rawValue))\(urlString)")
            return
        }

        guard error == nil else {
            XCTFail("Encountered an unexpected error. \(String(describing: error))")
            return
        }
        XCTAssertNotNil(data, "Expected non-nil data in response.")

        if let expectedStatusCode = expectedResponseStatusCode, let actualCode = (response as? HTTPURLResponse)?.statusCode {
            XCTAssertEqual(actualCode, expectedStatusCode, "The response HTTP status code did not match the expected status code.")
        } else {
            XCTWarn("Not asserting a particular status code for response.", at: requestUrl)
        }

        guard let receivedData = data else {
            XCTFail("Failed to retrieve data from API.")
            return
        }

        guard let mimeType = response?.mimeType, mimeType.lowercased().contains("json") else {
            XCTFail("Response mime type (\(response?.mimeType ?? "unknown")) is not JSON-based.")
            return
        }

        successResponseHandler(receivedData)

        completionExpectation.fulfill()
    }

    let task = URLSession.shared.dataTask(with: request, completionHandler: taskCompletion)
    task.resume()

    XCTWaiter().wait(for: [completionExpectation], timeout: 5)
}

"""# as LiteralSwiftCode
