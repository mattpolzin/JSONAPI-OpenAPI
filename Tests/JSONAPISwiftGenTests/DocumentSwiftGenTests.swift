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

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_singleInclude1ViaOpenAPI() {
        let openAPIStructure = try! TestPersonSingleInclude1Document.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonSingleDocument")

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_singleInclude2ViaOpenAPI() {
        let openAPIStructure = try! TestPersonSingleInclude2Document.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonSingleDocument")

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_nullableSingleViaOpenAPI() {
        let openAPIStructure = try! TestPersonNullableSingleDocument.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonSingleDocument")

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_collectionViaOpenAPI() {
        let openAPIStructure = try! TestPersonBatchDocument.openAPINode(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(structure: openAPIStructure,
                                                             swiftTypeName: "TestPersonBatchDocument")

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_tmp() {
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

typealias TestPersonSingleInclude1Document = JSONAPI.Document<
    SingleResourceBody<TestPerson>,
    NoMetadata,
    NoLinks,
    Include1<TestPerson>,
    NoAPIDescription,
    UnknownJSONAPIError>

struct TestThingyDescription: JSONAPI.ResourceObjectDescription {
    static let jsonType: String = "test_thingy"

    typealias Attributes = NoAttributes

    typealias Relationships = NoRelationships
}

typealias TestThingy = JSONAPI.ResourceObject<TestThingyDescription, NoMetadata, NoLinks, String>

typealias TestPersonSingleInclude2Document = JSONAPI.Document<
    SingleResourceBody<TestPerson>,
    NoMetadata,
    NoLinks,
    Include2<TestPerson, TestThingy>,
    NoAPIDescription,
    UnknownJSONAPIError>
