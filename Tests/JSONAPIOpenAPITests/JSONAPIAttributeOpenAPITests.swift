//
//  JSONAPIAttributeOpenAPITests.swift
//  JSONAPIOpenAPITests
//
//  Created by Mathew Polzin on 1/20/19.
//

import XCTest
import JSONAPI
import OpenAPIKit30
import JSONAPIOpenAPI
import SwiftCheck
import Sampleable

class JSONAPIAttributeOpenAPITests: XCTestCase {
}

// MARK: - Boolean
extension JSONAPIAttributeOpenAPITests {
	func test_BooleanAttribute() {
		let node = Attribute<Bool>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .boolean(.generic))
    let schema = node.value

		guard case .boolean(let contextA) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                allowedValues: nil
            )
        )
	}

	func test_NullableBooleanAttribute() {
		let node = Attribute<Bool?>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .boolean(.generic))
    let schema = node.value

		guard case .boolean(let contextA) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )
	}

	func test_OptionalBooleanAttribute() {
		let node = Attribute<Bool>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .boolean(.generic))
    let schema = node.value

		guard case .boolean(let contextA) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                allowedValues: nil
            )
        )
	}

	func test_OptionalNullableBooleanAttribute() {
		let node = Attribute<Bool?>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .boolean(.generic))
    let schema = node.value

		guard case .boolean(let contextA) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )
	}
}

// MARK: - Array of Strings
extension JSONAPIAttributeOpenAPITests {
	func test_Arrayttribute() {
		let node = Attribute<[String]>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .array(.generic))
    let schema = node.value

		guard case .array(let contextA, let arrayContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                allowedValues: nil
            )
        )

		let stringNode = JSONSchema.string(
            .init(
                format: .generic,
                required: true),
            .init()
        )

		XCTAssertEqual(arrayContext, .init(items: stringNode))
	}

	func test_NullableArrayAttribute() {
		let node = Attribute<[String]?>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .array(.generic))
    let schema = node.value

		guard case .array(let contextA, let arrayContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )

		let stringNode = JSONSchema.string(
            .init(
                format: .generic,
                required: true),
            .init()
        )

		XCTAssertEqual(arrayContext, .init(items: stringNode))
	}

	func test_OptionalArrayAttribute() {
		let node = Attribute<[String]>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .array(.generic))
    let schema = node.value

		guard case .array(let contextA, let arrayContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                allowedValues: nil
            )
        )

		let stringNode = JSONSchema.string(
            .init(
                format: .generic,
                required: true),
            .init()
        )

		XCTAssertEqual(arrayContext, .init(items: stringNode))
	}

	func test_OptionalNullableArrayAttribute() {
		let node = Attribute<[String]?>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .array(.generic))
    let schema = node.value

		guard case .array(let contextA, let arrayContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA, .init(
                format: .generic,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )

		let stringNode = JSONSchema.string(
            .init(
                format: .generic,
                required: true),
            .init()
        )

		XCTAssertEqual(arrayContext, .init(items: stringNode))
	}
}

// MARK: - Number
extension JSONAPIAttributeOpenAPITests {
	func test_NumberAttribute() {
		let node = Attribute<Double>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .number(.double))
    let schema = node.value

		guard case .number(let contextA, let numberContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_NullableNumberAttribute() {
		let node = Attribute<Double?>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .number(.double))
    let schema = node.value

		guard case .number(let contextA, let numberContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_OptionalNumberAttribute() {
		let node = Attribute<Double>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .number(.double))
    let schema = node.value

		guard case .number(let contextA, let numberContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: false,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_OptionalNullableNumberAttribute() {
		let node = Attribute<Double?>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .number(.double))
    let schema = node.value

		guard case .number(let contextA, let numberContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_FloatNumberAttribute() {
		let node = Attribute<Float>.openAPISchema

		XCTAssertEqual(node.jsonTypeFormat, .number(.float))
	}
}

// MARK: - Integer
extension JSONAPIAttributeOpenAPITests {
	func test_IntegerAttribute() {
		let node = Attribute<Int>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .integer(.generic))
    let schema = node.value

		guard case .integer(let contextA, let intContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(intContext, .init())
	}

	func test_NullableIntegerAttribute() {
		let node = Attribute<Int?>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .integer(.generic))
    let schema = node.value

		guard case .integer(let contextA, let intContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(intContext, .init())
	}

	func test_OptionalIntegerAttribute() {
		let node = Attribute<Int>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .integer(.generic))
    let schema = node.value

		guard case .integer(let contextA, let intContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                allowedValues: nil
            )
        )

		XCTAssertEqual(intContext, .init())
	}

	func test_OptionalNullableIntegerAttribute() {
		let node = Attribute<Int?>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .integer(.generic))
    let schema = node.value

		guard case .integer(let contextA, let intContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(intContext, .init())
	}
}

// MARK: - String
extension JSONAPIAttributeOpenAPITests {
	func test_StringAttribute() {
		let node = Attribute<String>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_NullableStringAttribute() {
		let node = Attribute<String?>.openAPISchema

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_OptionalStringAttribute() {
		let node = Attribute<String>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_OptionalNullableStringAttribute() {
		let node = Attribute<String?>?.openAPISchema

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}
}

// MARK: - Enum
// NOTE: `enum` Attributes only gain the automatic support for allowed values
// (`enum` property in the OpenAPI Spec) at the Entity scope. These attributes
// will all still have `allowedValues: nil` at the attribute scope.
extension JSONAPIAttributeOpenAPITests {
	func test_EnumAttribute() {
		let node = try! Attribute<EnumAttribute>.rawOpenAPISchema()

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_NullableEnumAttribute() {
        let node = try! Attribute<EnumAttribute?>.rawOpenAPISchema()

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_OptionalEnumAttribute() {
		let node = try! Attribute<EnumAttribute>?.rawOpenAPISchema()

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_OptionalNullableEnumAttribute() {
		let node = try! Attribute<EnumAttribute?>?.rawOpenAPISchema()

		XCTAssertFalse(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.generic))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .generic,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}
}

// MARK: - Date
extension JSONAPIAttributeOpenAPITests {
	func test_DateStringAttribute() {
		// TEST:
		// Encoder is set to use
		// formatter with date
		// with no time.

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		dateFormatter.locale = Locale(identifier: "en_US")

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .formatted(dateFormatter)

		let node = Attribute<Date>.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNotNil(node)

		XCTAssertTrue(node?.required ?? false)
		XCTAssertEqual(node?.jsonTypeFormat, .string(.date))
    let schema = node?.value

		guard case .string(let contextA, let stringContext)? = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA, .init(
                format: .date,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_DateStringAttribute_Sampleable() {
		// TEST:
		// Encoder is set to use
		// formatter with date
		// with no time.

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		dateFormatter.locale = Locale(identifier: "en_US")

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .formatted(dateFormatter)

        let node = try! Attribute<Date>.attributeOpenAPISchemaGuess(using: encoder)

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.date))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .date,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_DateTimeStringAttribute() {
		// TEST:
		// Encoder is set to use
		// formatter with date
		// with time.

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		dateFormatter.locale = Locale(identifier: "en_US")

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .formatted(dateFormatter)

		let node = Attribute<Date>.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNotNil(node)

		XCTAssertTrue(node?.required ?? false)
		XCTAssertEqual(node?.jsonTypeFormat, .string(.dateTime))
    let schema = node?.value

		guard case .string(let contextA, let stringContext)? = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .dateTime,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_DateTimeStringAttribute_Sampleable() {
		// TEST:
		// Encoder is set to use
		// formatter with date
		// with time.

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		dateFormatter.locale = Locale(identifier: "en_US")

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .formatted(dateFormatter)

		let node = try! Attribute<Date>.attributeOpenAPISchemaGuess(using: encoder)

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .string(.dateTime))
    let schema = node.value

		guard case .string(let contextA, let stringContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .dateTime,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(stringContext, .init())
	}

	func test_8601DateStringAttribute() {
		if #available(OSX 10.12, *) {
			// TEST:
			// Encoder is set to use
			// iso8601 date format

			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			encoder.dateEncodingStrategy = .iso8601

			let node = Attribute<Date>.dateOpenAPISchemaGuess(using: encoder)

			XCTAssertNotNil(node)

			XCTAssertTrue(node?.required ?? false)
			XCTAssertEqual(node?.jsonTypeFormat, .string(.dateTime))
    let schema = node?.value

			guard case .string(let contextA, let stringContext)? = schema else {
				XCTFail("Expected string Node")
				return
			}

			XCTAssertEqual(
                contextA,
                .init(
                    format: .dateTime,
                    required: true,
                    allowedValues: nil
                )
            )

			XCTAssertEqual(stringContext, .init())
		}
	}

	func test_8601DateStringAttribute_Sampleable() {
		if #available(OSX 10.12, *) {
			// TEST:
			// Encoder is set to use
			// iso8601 date format

			let encoder = JSONEncoder()
			encoder.outputFormatting = .prettyPrinted
			encoder.dateEncodingStrategy = .iso8601

			let node = try! Attribute<Date>.attributeOpenAPISchemaGuess(using: encoder)

			XCTAssertTrue(node.required)
			XCTAssertEqual(node.jsonTypeFormat, .string(.dateTime))
    let schema = node.value

			guard case .string(let contextA, let stringContext) = schema else {
				XCTFail("Expected string Node")
				return
			}

			XCTAssertEqual(
                contextA,
                .init(
                    format: .dateTime,
                    required: true,
                    allowedValues: nil
                )
            )

			XCTAssertEqual(stringContext, .init())
		}
	}

	func test_DateNumberAttribute() {
		// TEST:
		// Encoder is set to use
		// seconds since 1970 as
		// date format

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .secondsSince1970

		let node = Attribute<Date>.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNotNil(node)

		XCTAssertTrue(node?.required ?? false)
		XCTAssertEqual(node?.jsonTypeFormat, .number(.double))
    let schema = node?.value

		guard case .number(let contextA, let numberContext)? = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_DateNumberAttribute_Sampleable() {
		// TEST:
		// Encoder is set to use
		// seconds since 1970 as
		// date format

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .secondsSince1970

		let node = try! Attribute<Date>.attributeOpenAPISchemaGuess(using: encoder)

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .number(.double))
    let schema = node.value

		guard case .number(let contextA, let numberContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_DateDeferredAttribute() {
		// TEST:
		// Encoder is set to use
		// Date default encoding

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .deferredToDate

		let node = Attribute<Date>.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNil(node)
	}

	func test_DateDeferredAttribute_Sampleable() {
		// TEST:
		// Encoder is set to use
		// Date default encoding

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .deferredToDate

		let node = try! Attribute<Date>.attributeOpenAPISchemaGuess(using: encoder)

		XCTAssertTrue(node.required)
		XCTAssertEqual(node.jsonTypeFormat, .number(.double))
    let schema = node.value

		guard case .number(let contextA, let numberContext) = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_NullableDateAttribute() {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .secondsSince1970

		let node = Attribute<Date?>.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNotNil(node)

		XCTAssertTrue(node?.required ?? false)
		XCTAssertEqual(node?.jsonTypeFormat, .number(.double))
    let schema = node?.value

		guard case .number(let contextA, let numberContext)? = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: true,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_OptionalDateAttribute() {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .secondsSince1970

		let node = Attribute<Date>?.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNotNil(node)

		XCTAssertFalse(node?.required ?? true)
		XCTAssertEqual(node?.jsonTypeFormat, .number(.double))
    let schema = node?.value

		guard case .number(let contextA, let numberContext)? = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: false,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}

	func test_OptionalNullableDateAttribute() {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .secondsSince1970

		let node = Attribute<Date?>?.dateOpenAPISchemaGuess(using: encoder)

		XCTAssertNotNil(node)

		XCTAssertFalse(node?.required ?? true)
		XCTAssertEqual(node?.jsonTypeFormat, .number(.double))
    let schema = node?.value

		guard case .number(let contextA, let numberContext)? = schema else {
			XCTFail("Expected string Node")
			return
		}

		XCTAssertEqual(
            contextA,
            .init(
                format: .double,
                required: false,
                nullable: true,
                allowedValues: nil
            )
        )

		XCTAssertEqual(numberContext, .init())
	}
}

// MARK: - Test Types
extension JSONAPIAttributeOpenAPITests {
	enum EnumAttribute: String, Codable, CaseIterable, RawOpenAPISchemaType {
		case one
		case two
	}

    enum EnumAttribute2: String, Codable, CaseIterable, RawOpenAPISchemaType, AnyJSONCaseIterable {
        case here
        case there
    }
}

extension Date: Sampleable {
	public static var sample: Date {
		return TimeInterval.arbitrary.map { Date(timeIntervalSince1970: $0) }.generate
	}
}
