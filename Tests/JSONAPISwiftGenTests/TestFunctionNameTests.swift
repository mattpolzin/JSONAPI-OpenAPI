//
//  TestFunctionNameTests.swift
//  
//
//  Created by Mathew Polzin on 4/26/20.
//

import JSONAPISwiftGen
import OpenAPIKit30
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

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["go", "_", "continue", "do", "try", "accept"]),
                endpoint: .post,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello_world➎")!
            )
        )

        assertReflexiveRawValue(
            TestFunctionName(
                path: .init(["hello.world", "hi"]),
                endpoint: .post,
                direction: .request,
                context: TestFunctionLocalContext(functionName: "_hello_world➎")!
            )
        )
    }

    func test_periodInPath() {
        let t1 = TestFunctionName(
            path: .init(["hello.world", "hi"]),
            endpoint: .post,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello_world➎")!
        )
        XCTAssertEqual(t1.fullyQualifiedTestFunctionName, "hello_world.hi.POST.Request._hello_world➎")
        XCTAssertEqual(t1.rawValue, "test__hello❺world➍hi➍POST➍Request➍_hello_world➎")
        XCTAssertEqual(t1.testName, "_hello_world➎")

        XCTAssertEqual(TestFunctionName(rawValue: t1.rawValue)?.path, .init(["hello.world", "hi"]))
    }

    func test_reservedWordsInPath() {
        let t1 = TestFunctionName(
            path: .init(["go", "_", "continue", "do", "try", "accept"]),
            endpoint: .post,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello_world➎")!
        )
        XCTAssertTrue(t1.fullyQualifiedTestFunctionName.contains("go."))

        XCTAssertFalse(t1.fullyQualifiedTestFunctionName.contains("._."))
        XCTAssertFalse(t1.fullyQualifiedTestFunctionName.contains(".do."))
        XCTAssertFalse(t1.fullyQualifiedTestFunctionName.contains(".continue."))
        XCTAssertFalse(t1.fullyQualifiedTestFunctionName.contains(".try."))
    }

    func test_onlyEscapeKeywords() {
        let t1 = TestFunctionName(
            path: .init(["go", "domain"]),
            endpoint: .post,
            direction: .request,
            context: TestFunctionLocalContext(functionName: "_hello_world➎")!
        )
        XCTAssertTrue(t1.fullyQualifiedTestFunctionName.contains("domain"))
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
