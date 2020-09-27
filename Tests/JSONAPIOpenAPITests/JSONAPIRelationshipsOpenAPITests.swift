//
//  JSONAPIRelationshipsOpenAPITests.swift
//  JSONAPI
//
//  Created by Mathew Polzin on 1/14/19.
//

import Foundation
import XCTest
import JSONAPI
import OpenAPIKit
import JSONAPITesting
import JSONAPIOpenAPI

class JSONAPIRelationshipsOpenAPITests: XCTestCase {

	func test_ToOne() {
		let node = ToOneRelationship<TestEntity1, NoIdMetadata, NoMetadata, NoLinks>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .object(.generic))

		guard case .object(let contextA, let objectContext1) = node else {
			XCTFail("Expected object Node")
			return
		}

		XCTAssertEqual(contextA, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext1.additionalProperties)
		XCTAssertEqual(Array(objectContext1.properties.keys), ["data"])

		guard case .object(let contextB, let objectContext2)? = objectContext1.properties["data"] else {
			XCTFail("Expected object node within properties")
			return
		}

		XCTAssertEqual(contextB, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext2.additionalProperties)
		XCTAssertEqual(Set(objectContext2.properties.keys), Set(["id", "type"]))
	}

	func test_OptionalToOne() {
		let node = ToOneRelationship<TestEntity1, NoIdMetadata, NoMetadata, NoLinks>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .object(.generic))

		guard case .object(let contextA, let objectContext1) = node else {
			XCTFail("Expected object Node")
			return
		}

		XCTAssertEqual(contextA, .init(format: .generic,
									   required: false,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext1.additionalProperties)
		XCTAssertEqual(Array(objectContext1.properties.keys), ["data"])

		guard case .object(let contextB, let objectContext2)? = objectContext1.properties["data"] else {
			XCTFail("Expected object node within properties")
			return
		}

		XCTAssertEqual(contextB, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext2.additionalProperties)
		XCTAssertEqual(Set(objectContext2.properties.keys), Set(["id", "type"]))
	}

	func test_NullableToOne() {
		let node = ToOneRelationship<TestEntity1?, NoIdMetadata, NoMetadata, NoLinks>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .object(.generic))

		guard case .object(let contextA, let objectContext1) = node else {
			XCTFail("Expected object Node")
			return
		}

		XCTAssertEqual(contextA, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext1.additionalProperties)
		XCTAssertEqual(Array(objectContext1.properties.keys), ["data"])

		guard case .object(let contextB, let objectContext2)? = objectContext1.properties["data"] else {
			XCTFail("Expected object node within properties")
			return
		}

		XCTAssertEqual(contextB, .init(format: .generic,
									   required: true,
									   nullable: true,
									   allowedValues: nil))

		XCTAssertNil(objectContext2.additionalProperties)
		XCTAssertEqual(Set(objectContext2.properties.keys), Set(["id", "type"]))
	}

	func test_OptionalNullableToOne() {
		let node = ToOneRelationship<TestEntity1?, NoIdMetadata, NoMetadata, NoLinks>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .object(.generic))

		guard case .object(let contextA, let objectContext1) = node else {
			XCTFail("Expected object Node")
			return
		}

		XCTAssertEqual(contextA, .init(format: .generic,
									   required: false,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext1.additionalProperties)
		XCTAssertEqual(Array(objectContext1.properties.keys), ["data"])

		guard case .object(let contextB, let objectContext2)? = objectContext1.properties["data"] else {
			XCTFail("Expected object node within properties")
			return
		}

		XCTAssertEqual(contextB, .init(format: .generic,
									   required: true,
									   nullable: true,
									   allowedValues: nil))

		XCTAssertNil(objectContext2.additionalProperties)
		XCTAssertEqual(Set(objectContext2.properties.keys), Set(["id", "type"]))
	}

	func test_ToMany() {
		let node = ToManyRelationship<TestEntity1, NoIdMetadata, NoMetadata, NoLinks>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .object(.generic))

		guard case .object(let contextA, let objectContext1) = node else {
			XCTFail("Expected object Node")
			return
		}

		XCTAssertEqual(contextA, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext1.additionalProperties)
		XCTAssertEqual(Array(objectContext1.properties.keys), ["data"])

		guard case .array(let contextB, let arrayContext)? = objectContext1.properties["data"] else {
			XCTFail("Expected array node within properties")
			return
		}

		XCTAssertEqual(contextB, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		guard case .object(let contextC, let objectContext2)? = arrayContext.items else {
			XCTFail("Expected object node within items")
			return
		}

		XCTAssertEqual(contextC, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext2.additionalProperties)
		XCTAssertEqual(Set(objectContext2.properties.keys), Set(["id", "type"]))
	}

	func test_OptionalToMany() {
		let node = ToManyRelationship<TestEntity1, NoIdMetadata, NoMetadata, NoLinks>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .object(.generic))

		guard case .object(let contextA, let objectContext1) = node else {
			XCTFail("Expected object Node")
			return
		}

		XCTAssertEqual(contextA, .init(format: .generic,
									   required: false,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext1.additionalProperties)
		XCTAssertEqual(Array(objectContext1.properties.keys), ["data"])

		guard case .array(let contextB, let arrayContext)? = objectContext1.properties["data"] else {
			XCTFail("Expected array node within properties")
			return
		}

		XCTAssertEqual(contextB, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		guard case .object(let contextC, let objectContext2)? = arrayContext.items else {
			XCTFail("Expected object node within items")
			return
		}

		XCTAssertEqual(contextC, .init(format: .generic,
									   required: true,
									   nullable: false,
									   allowedValues: nil))

		XCTAssertNil(objectContext2.additionalProperties)
		XCTAssertEqual(Set(objectContext2.properties.keys), Set(["id", "type"]))
	}
}

// MARK: Test Types
extension JSONAPIRelationshipsOpenAPITests {
	enum TestEntityType1: ResourceObjectDescription {
		static var jsonType: String { return "test_entities"}

		typealias Attributes = NoAttributes
		typealias Relationships = NoRelationships
	}

	typealias TestEntity1 = BasicEntity<TestEntityType1>

	enum TestEntityType2: ResourceObjectDescription {
		static var jsonType: String { return "second_test_entities"}

		typealias Attributes = NoAttributes

		struct Relationships: JSONAPI.Relationships {
			let other: ToOneRelationship<TestEntity1, NoIdMetadata, NoMetadata, NoLinks>
		}
	}

	typealias TestEntity2 = BasicEntity<TestEntityType2>
}
