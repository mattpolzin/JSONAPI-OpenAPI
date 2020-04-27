//
//  TestFunctionNameTests.swift
//  
//
//  Created by Mathew Polzin on 4/26/20.
//

import JSONAPISwiftGen
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
    }

    func assertReflexiveRawValue(_ testName: TestFunctionName, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(testName, TestFunctionName(rawValue: testName.rawValue), file: file, line: line)
    }
}
