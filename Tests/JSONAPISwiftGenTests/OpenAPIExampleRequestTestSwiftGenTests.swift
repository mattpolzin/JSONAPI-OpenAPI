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
            testSuiteConfiguration: .init(),
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
            testSuiteConfiguration: .init(),
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

    func test_hostNotOverridden() throws {
        let server = OpenAPI.Server(url: URL(string: "http://website.com")!)
        let gen = try OpenAPIExampleRequestTestSwiftGen(
            server: server,
            pathComponents: "/hello/world",
            parameters: [],
            testSuiteConfiguration: .init(),
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
        XCTAssertEqual(decls.first?.swiftCode.split(separator: "\n").first { $0.contains("requestUrl") }, #"let requestUrl: URL = URL(string: "http://website.com/hello/world")!"#)
    }

    func test_hostOverriddenByTest() throws {
        let server = OpenAPI.Server(url: URL(string: "http://website.com")!)
        let serverOverride = OpenAPI.Server(url: URL(string: "http://hi.hello")!)
        let gen = try OpenAPIExampleRequestTestSwiftGen(
            server: server,
            pathComponents: "/hello/world",
            parameters: [],
            testSuiteConfiguration: .init(),
            testProperties: try .init(
                name: "test",
                server: serverOverride,
                props: ["parameters": [String:String]()]
            ),
            exampleResponseDataPropName: nil,
            responseBodyType: "ResponseType",
            expectedHttpStatus: .default
        )

        let decls = gen.decls

        // assert expected status code is set
        XCTAssertEqual(decls.first?.swiftCode.split(separator: "\n").first { $0.contains("requestUrl") }, #"let requestUrl: URL = URL(string: "http://hi.hello/hello/world")!"#)
    }

    func test_hostOverriddenForWholeSuite() throws {
        let server = OpenAPI.Server(url: URL(string: "http://website.com")!)
        let serverOverride = OpenAPI.Server(url: URL(string: "http://hi.hello")!)
        let suiteServerOverride = URL(string: "http://cool.beans")!
        let gen = try OpenAPIExampleRequestTestSwiftGen(
            server: server,
            pathComponents: "/hello/world",
            parameters: [],
            testSuiteConfiguration: .init(apiHostOverride: suiteServerOverride),
            testProperties: try .init(
                name: "test",
                server: serverOverride,
                props: ["parameters": [String:String]()]
            ),
            exampleResponseDataPropName: nil,
            responseBodyType: "ResponseType",
            expectedHttpStatus: .default
        )

        let decls = gen.decls

        // assert expected status code is set
        XCTAssertEqual(decls.first?.swiftCode.split(separator: "\n").first { $0.contains("requestUrl") }, #"let requestUrl: URL = URL(string: "http://cool.beans/hello/world")!"#)
    }
}
