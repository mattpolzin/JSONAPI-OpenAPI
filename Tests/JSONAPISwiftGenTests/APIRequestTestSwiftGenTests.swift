//
//  APIRequestTestSwiftGenTests.swift
//  
//
//  Created by Mathew Polzin on 11/6/19.
//

import XCTest
import JSONAPI
import JSONAPITesting

final class APIRequestTestSwiftGenTests: XCTestCase {

}

// MARK: - Function written to generated test suites
struct DummyComparison: PropertyComparable {
    let differences: NamedDifferences

    public init(name: String, _ comparison: Comparison) {
        switch comparison {
        case .same:
            differences = [:]
        case .prebuilt,
             .different:
            differences = [name: comparison.rawValue]
        }
    }
}

func compare<T, DT: EncodableJSONAPIDocument>(_ one: DT, _ two: DT) -> PropertyComparable where DT.PrimaryResourceBody == SingleResourceBody<T>, T: ResourceObjectType, DT.Body: Equatable {
    return one.compare(to: two)
}

func compare<T, DT: EncodableJSONAPIDocument>(_ one: DT, _ two: DT) -> PropertyComparable where DT.PrimaryResourceBody == SingleResourceBody<T?>, T: ResourceObjectType, DT.Body: Equatable {
    return one.compare(to: two)
}

func compare<T, DT: EncodableJSONAPIDocument>(_ one: DT, _ two: DT) -> PropertyComparable where DT.PrimaryResourceBody == ManyResourceBody<T>, T: ResourceObjectType, DT.Body: Equatable {
    return one.compare(to: two)
}

func compare<T>(_ one: T, _ two: T) -> PropertyComparable where T: Equatable {

    let name = String(describing: type(of: one))

    guard one == two else {
        return DummyComparison(name: name, .different(
            String(describing: one),
            String(describing: two)
            ))
    }

    return DummyComparison(name: name, .same)
}

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
            let comparison = compare(document, expectedResponseBody)
            XCTAssert(comparison.isSame, comparison.rawValue)
        }

        completionExpectation.fulfill()
    }

    let task = URLSession.shared.dataTask(with: request, completionHandler: taskCompletion)
    task.resume()

    XCTWaiter().wait(for: [completionExpectation], timeout: 5)
}
