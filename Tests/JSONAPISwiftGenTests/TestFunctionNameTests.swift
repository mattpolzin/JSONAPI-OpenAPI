//
//  TestFunctionNameTests.swift
//  
//
//  Created by Mathew Polzin on 4/26/20.
//

import JSONAPISwiftGen
import OpenAPIKit
import XCTest

final class TestFunctionNameTests: XCTestCase {
    func test_reflexivityOfRawValue() {
        assertReflexiveRawValue(
            TestFunctionName(
                path: .init([]),
                endpoint: .get,
                direction: .request,
                testName: "hello"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello"]),
                endpoint: .get,
                direction: .request,
                testName: "hello"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello", "world"]),
                endpoint: .get,
                direction: .request,
                testName: "hello"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init([]),
                endpoint: .post,
                direction: .request,
                testName: "hello"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init([]),
                endpoint: .get,
                direction: .response,
                testName: "hello"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello"]),
                endpoint: .patch,
                direction: .response,
                testName: "hello"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello", "world"]),
                endpoint: .get,
                direction: .request,
                testName: "hello_world"
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello_world", "v2"]),
                endpoint: .get,
                direction: .request,
                testName: "hello_world"
            )
        )
    }

    func test_statusCodeExtraction() {
        let test1 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            testName: "hello_world"
        )
        XCTAssertNil(test1.testStatusCodeGuess)

        let test2 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            testName: "hello_world__hi"
        )
        XCTAssertNil(test2.testStatusCodeGuess)

        let test3 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            testName: "hello_world__404"
        )
        XCTAssertEqual(test3.testStatusCodeGuess, OpenAPI.Response.StatusCode.status(code: 404))

        let test4 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            testName: "hello_world__3xx"
        )
        XCTAssertEqual(test4.testStatusCodeGuess, OpenAPI.Response.StatusCode.range(.redirect))

        let test5 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            testName: "hello_world__default"
        )
        XCTAssertEqual(test5.testStatusCodeGuess, OpenAPI.Response.StatusCode.default)
    }

    func assertReflexiveRawValue(_ testName: TestFunctionName, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(testName, TestFunctionName(rawValue: testName.rawValue), file: file, line: line)
    }
}
