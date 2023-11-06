//
//  APIRequestTestSwiftGenTests.swift
//  
//
//  Created by Mathew Polzin on 11/6/19.
//

import XCTest
import JSONAPI
import JSONAPITesting
import OpenAPIKit30
import JSONAPISwiftGen

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class APIRequestTestSwiftGenTests: XCTestCase {
    func test_undefinedPathParameters() {
        XCTAssertThrowsError(
            try APIRequestTestSwiftGen(
                method: .post,
                server: OpenAPI.Server(url: URL(string: "http://website.com")!),
                pathComponents: "/widgets/{widget_id}",
                parameters: []
            )
        )
    }

    func test_noUndefinedPathParameters() throws {
        // just prove this does not throw for now.

        // TODO: test could actually test for the given parameter
        // being part of the resulting function signature or even more.
        _ = try APIRequestTestSwiftGen(
            method: .post,
            server: OpenAPI.Server(url: URL(string: "http://website.com")!),
            pathComponents: "/widgets/{widget_id}",
            parameters: [
                OpenAPI.Parameter(
                    name: "widget_id",
                    context: .path,
                    schema: .string
                ).dereferenced(in: .noComponents)
            ]
        )
    }
}

// MARK: - START - Function written to generated test suites
/// A session stored globally that does not cache responses on disk.
let session = URLSession(
    configuration: .ephemeral
)

/// Log warning after test case logs
func XCTWarn(_ message: String, at url: URL) {
    print("[\(url.absoluteString)] : warning - \(message)")
}

enum HttpMethod: String, CaseIterable, Equatable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case options = "OPTIONS"
    case head = "HEAD"
    case trace = "TRACE"
}

/// JSONAPI Document Response request test
func makeTestRequest<RequestBody, ResponseBody>(
    method: HttpMethod,
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
        method: method,
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
    method: HttpMethod,
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
        method: method,
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
    method: HttpMethod,
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

    request.httpMethod = method.rawValue

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

    let task = session.dataTask(with: request, completionHandler: taskCompletion)
    task.resume()

    XCTWaiter().wait(for: [completionExpectation], timeout: 5)
}

// MARK: - END - Function written to generated test suites


// MARK: - Test Types
extension APIRequestTestSwiftGenTests {
    enum TestEntityDescription: ResourceObjectDescription {
        static var jsonType: String { return "test" }

        struct Attributes: JSONAPI.Attributes {
            let name: Attribute<String>
            let date: Attribute<Date>

            static var sample: Attributes {
                return .init(name: "hello world",
                             date: .init(value: Date()))
            }
        }

        typealias Relationships = NoRelationships
    }

    typealias TestEntity = ResourceObject<TestEntityDescription, NoMetadata, NoLinks, String>

    typealias SingleEntityDocument = Document<SingleResourceBody<TestEntity>, NoMetadata, NoLinks, NoIncludes, NoAPIDescription, UnknownJSONAPIError>

    typealias ManyEntityDocument = Document<ManyResourceBody<TestEntity>, NoMetadata, NoLinks, NoIncludes, NoAPIDescription, UnknownJSONAPIError>

    typealias DocumentWithIncludes = Document<SingleResourceBody<TestEntity>, NoMetadata, NoLinks, Include1<TestEntity>, NoAPIDescription, UnknownJSONAPIError>

    enum TestEntityDescription2: ResourceObjectDescription {
        static var jsonType: String { return "test2" }

        typealias Attributes = NoAttributes

        typealias Relationships = NoRelationships
    }

    typealias TestEntity2 = ResourceObject<TestEntityDescription2, NoMetadata, NoLinks, String>

    typealias DocumentWithMultipleTypesOfIncludes = Document<SingleResourceBody<TestEntity>, NoMetadata, NoLinks, Include2<TestEntity, TestEntity2>, NoAPIDescription, UnknownJSONAPIError>
}
