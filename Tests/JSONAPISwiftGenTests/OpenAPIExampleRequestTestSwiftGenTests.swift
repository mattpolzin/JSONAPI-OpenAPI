//
//  OpenAPIExampleRequestTestSwiftGenTests.swift
//  
//
//  Created by Mathew Polzin on 4/24/20.
//

import XCTest
import Foundation
import OpenAPIKit
import JSONAPISwiftGen

final class OpenAPIExampleRequestTestSwiftGenTests: XCTestCase {
    func test_statusCodeDefined() throws {
        let server = OpenAPI.Server(url: URL(string: "http://website.com")!)
        let gen = try OpenAPIExampleRequestTestSwiftGen(
            server: server,
            pathComponents: "/hello/world",
            parameters: [],
            testProperties: try .init(
                name: "test",
                server: server,
                props: ["parameters": [String:String]()]
            ),
            exampleResponseDataPropName: nil,
            responseBodyType: "ResponseType",
            expectedHttpStatus: 200
        )

        let decls = gen.decls

        // assert expected status code is set
        XCTAssertEqual(decls.first?.swiftCode.split(separator: "\n").first { $0.contains("expectedResponseStatusCode") }, "let expectedResponseStatusCode: Int? = 200")
    }

    func test_statusCodeUndefined() throws {
        let server = OpenAPI.Server(url: URL(string: "http://website.com")!)
        let gen = try OpenAPIExampleRequestTestSwiftGen(
            server: server,
            pathComponents: "/hello/world",
            parameters: [],
            testProperties: try .init(
                name: "test",
                server: server,
                props: ["parameters": [String:String]()]
            ),
            exampleResponseDataPropName: nil,
            responseBodyType: "ResponseType",
            expectedHttpStatus: .default
        )

        let decls = gen.decls

        // assert expected status code is set
        XCTAssertEqual(decls.first?.swiftCode.split(separator: "\n").first { $0.contains("expectedResponseStatusCode") }, "let expectedResponseStatusCode: Int? = nil")
    }
}
