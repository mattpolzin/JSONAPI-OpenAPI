//
//  APIRequestTestSwiftGenTests.swift
//  
//
//  Created by Mathew Polzin on 11/6/19.
//

import XCTest
import JSONAPI
import JSONAPITesting

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class APIRequestTestSwiftGenTests: XCTestCase {
}

// MARK: - START - Function written to generated test suites
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
            let urlString = error.failureURLString.map { " \($0)" } ?? ""
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
