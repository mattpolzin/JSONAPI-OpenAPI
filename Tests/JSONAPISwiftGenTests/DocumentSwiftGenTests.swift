//
//  DocumentSwiftGenTests.swift
//  JSONAPISwiftGenTests
//
//  Created by Mathew Polzin on 9/7/19.
//

import XCTest
import Sampleable
import JSONAPIOpenAPI
import JSONAPISwiftGen

class DocumentSwiftGenTests: XCTestCase {
    func test_singleViaOpenAPI() {
        let openAPIStructure = try! TestPersonSingleDocument.SuccessDocument.openAPISchema(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(swiftTypeName: "TestPersonSingleDocument",
                                                             structure: openAPIStructure)

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_singleInclude1ViaOpenAPI() {
        let openAPIStructure = try! TestPersonSingleInclude1Document.SuccessDocument.openAPISchema(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(swiftTypeName: "TestPersonSingleDocument",
                                                             structure: openAPIStructure)

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_singleInclude2ViaOpenAPI() {
        let openAPIStructure = try! TestPersonSingleInclude2Document.SuccessDocument.openAPISchema(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(swiftTypeName: "TestPersonSingleDocument",
                                                             structure: openAPIStructure)

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_nullableSingleViaOpenAPI() {
        let openAPIStructure = try! TestPersonNullableSingleDocument.SuccessDocument.openAPISchema(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(swiftTypeName: "TestPersonSingleDocument",
                                                             structure: openAPIStructure)

        print(try! testDocumentSwiftGen.resourceObjectGenerators.map { try $0.formattedSwiftCode() }.joined(separator: "\n"))
        print(try! testDocumentSwiftGen.formattedSwiftCode())
    }

    func test_collectionViaOpenAPI() {
        let openAPIStructure = try! TestPersonBatchDocument.SuccessDocument.openAPISchema(using: testEncoder)

        let testDocumentSwiftGen = try! DataDocumentSwiftGen(swiftTypeName: "TestPersonBatchDocument",
                                                             structure: openAPIStructure)

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
    BasicJSONAPIError<String>>

typealias TestPersonNullableSingleDocument = JSONAPI.Document<
    SingleResourceBody<TestPerson?>,
    NoMetadata,
    NoLinks,
    NoIncludes,
    NoAPIDescription,
    BasicJSONAPIError<String>>

typealias TestPersonBatchDocument = JSONAPI.Document<
    ManyResourceBody<TestPerson>,
    NoMetadata,
    NoLinks,
    NoIncludes,
    NoAPIDescription,
    BasicJSONAPIError<String>>

typealias TestPersonSingleInclude1Document = JSONAPI.Document<
    SingleResourceBody<TestPerson>,
    NoMetadata,
    NoLinks,
    Include1<TestPerson>,
    NoAPIDescription,
    BasicJSONAPIError<String>>

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
    BasicJSONAPIError<String>>
