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
                context: TestFunctionLocalContext(functionName: "_hello➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello"]),
                endpoint: .get,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello", "world"]),
                endpoint: .get,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init([]),
                endpoint: .post,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init([]),
                endpoint: .get,
                direction: .response,
                context: TestFunctionLocalContext(functionName: "_hello➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello"]),
                endpoint: .patch,
                direction: .response,
                context: TestFunctionLocalContext(functionName: "_hello➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello", "world"]),
                endpoint: .get,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello_world➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello_world", "v2"]),
                endpoint: .get,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello_world➎")!
            )
        )
    }

    func test_statusCodeExtraction() {
        let test1 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello_world➎")!
        )
        XCTAssertNil(test1.testStatusCode)

        let test3 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello➎world__404")!
        )
        XCTAssertEqual(test3.testStatusCode, OpenAPI.Response.StatusCode.status(code: 404))

        let test4 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello➎world__3xx")!
        )
        XCTAssertEqual(test4.testStatusCode, OpenAPI.Response.StatusCode.range(.redirect))

        let test5 = TestFunctionName(
            path: .init(["hello_world", "v2"]),
            endpoint: .get,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello➎world__default")!
        )
        XCTAssertEqual(test5.testStatusCode, OpenAPI.Response.StatusCode.default)
    }

    func assertReflexiveRawValue(_ testName: TestFunctionName, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(testName, TestFunctionName(rawValue: testName.rawValue), file: file, line: line)
    }
}
