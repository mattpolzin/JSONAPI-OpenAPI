//
//  TestFunctionLocalContextTests.swift
//  
//
//  Created by Mathew Polzin on 6/21/20.
//

import Foundation
import XCTest
import OpenAPIKit30
import JSONAPISwiftGen

final class TestFunctionLocalContextTests: XCTestCase {
    func test_reflexiveFunctionName() {
        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                contextPrefix: "test_prefix",
                slug: "function_slug",
                statusCode: 200
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                contextPrefix: "test_prefix",
                slug: "function_slug",
                statusCode: .default
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                contextPrefix: "test_prefix",
                slug: "function_slug",
                statusCode: .range(.information)
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                contextPrefix: "test_prefix",
                slug: "function_slug",
                statusCode: nil
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                slug: "function_slug",
                statusCode: 200
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                slug: "function_slug",
                statusCode: nil
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                contextPrefix: "test_prefix",
                slug: nil,
                statusCode: 200
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                contextPrefix: "test_prefix",
                slug: nil,
                statusCode: nil
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                slug: nil,
                statusCode: 200
            )
        )

        assertReflexiveFunctionName(
            TestFunctionLocalContext(
                slug: nil,
                statusCode: nil
            )
        )
    }

    func test_statusCodes() {
        let test1 = TestFunctionLocalContext(functionName: "_hello_world➎")
        XCTAssertNotNil(test1)
        XCTAssertNil(test1?.statusCode)

        let test2 = TestFunctionLocalContext(functionName: "_hello➎world__hi")
        XCTAssertNil(test2)

        let test3 = TestFunctionLocalContext(functionName: "_hello➎world__404")
        XCTAssertNotNil(test3)
        XCTAssertEqual(test3?.statusCode, OpenAPI.Response.StatusCode.status(code: 404))

        let test4 = TestFunctionLocalContext(functionName: "_hello➎world__3xx")
        XCTAssertNotNil(test4)
        XCTAssertEqual(test4?.statusCode, OpenAPI.Response.StatusCode.range(.redirect))

        let test5 = TestFunctionLocalContext(functionName: "_hello➎world__default")
        XCTAssertNotNil(test5)
        XCTAssertEqual(test5?.statusCode, OpenAPI.Response.StatusCode.default)
    }

    func assertReflexiveFunctionName(_ testContext: TestFunctionLocalContext, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(testContext, TestFunctionLocalContext(functionName: testContext.functionName), file: file, line: line)
    }
}
