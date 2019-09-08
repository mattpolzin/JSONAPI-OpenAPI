//
//  DocumentSwiftGenTests.swift
//  JSONAPISwiftGenTests
//
//  Created by Mathew Polzin on 9/7/19.
//

import XCTest
import JSONAPISwiftGen
import JSONAPI
import Sampleable
import OpenAPIKit
import JSONAPIOpenAPI

class DocumentSwiftGenTests: XCTestCase {
    func test_singleViaOpenAPI() {
        let openAPIStructure = try! TestPersonSingleDocument.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonSingleDocument")

        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_nullableSingleViaOpenAPI() {
        let openAPIStructure = try! TestPersonNullableSingleDocument.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonSingleDocument")

        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_collectionViaOpenAPI() {
        let openAPIStructure = try! TestPersonBatchDocument.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonBatchDocument")

        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }
}

typealias TestPersonSingleDocument = JSONAPI.Document<
    SingleResourceBody<TestPerson>,
    NoMetadata,
    NoLinks,
    NoIncludes,
    NoAPIDescription,
    UnknownJSONAPIError>

typealias TestPersonNullableSingleDocument = JSONAPI.Document<
    SingleResourceBody<TestPerson?>,
    NoMetadata,
    NoLinks,
    NoIncludes,
    NoAPIDescription,
    UnknownJSONAPIError>

typealias TestPersonBatchDocument = JSONAPI.Document<
    ManyResourceBody<TestPerson>,
    NoMetadata,
    NoLinks,
    NoIncludes,
    NoAPIDescription,
    UnknownJSONAPIError>
