//
//  JSONAPIAttribute+OpenAPI.swift
//  JSONAPIOpenAPI
//
//  Created by Mathew Polzin on 1/28/19.
//

import JSONAPI
import OpenAPIKit30
import OpenAPIReflection30
import Foundation
import Sampleable

private protocol _Optional {}
extension Optional: _Optional {}

private protocol Wrapper {
	associatedtype Wrapped
}
extension Optional: Wrapper {}

public protocol OpenAPIAttributeType {
    static func attributeOpenAPISchemaGuess(using encoder: JSONEncoder) throws -> JSONSchema
}

// MARK: Attribute
extension Attribute: OpenAPISchemaType where RawValue: OpenAPISchemaType {
    static public var openAPISchema: JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if !RawValue.openAPISchema.required {
			return RawValue.openAPISchema.requiredSchemaObject().nullableSchemaObject()
		}
		return RawValue.openAPISchema
	}
}

extension Attribute: RawOpenAPISchemaType where RawValue: RawOpenAPISchemaType {
	static public func rawOpenAPISchema() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.rawOpenAPISchema().required {
			return try RawValue.rawOpenAPISchema().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.rawOpenAPISchema()
	}
}

extension Attribute: DateOpenAPISchemaType where RawValue: DateOpenAPISchemaType {
	public static func dateOpenAPISchemaGuess(using encoder: JSONEncoder) -> JSONSchema? {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if
			!(RawValue.dateOpenAPISchemaGuess(using: encoder)?.required ?? true) {
			return RawValue.dateOpenAPISchemaGuess(using: encoder)?.requiredSchemaObject().nullableSchemaObject()
		}
		return RawValue.dateOpenAPISchemaGuess(using: encoder)
	}
}

extension Attribute: AnyRawRepresentable where RawValue: AnyRawRepresentable {
    public static var rawValueType: Any.Type { return RawValue.rawValueType }
}

extension Attribute: AnyJSONCaseIterable where RawValue: AnyJSONCaseIterable {
	public static func allCases(using encoder: JSONEncoder) -> [AnyCodable] {
		return RawValue.allCases(using: encoder)
	}
}

extension Attribute: OpenAPIAttributeType where RawValue: Sampleable, RawValue: Encodable {
    public static func attributeOpenAPISchemaGuess(using encoder: JSONEncoder) throws -> JSONSchema {
        // If the RawValue is not required, we actually consider it
        // nullable. To be not required is for the Attribute itself
        // to be optional.
        if try !OpenAPIReflection30.genericOpenAPISchemaGuess(for: RawValue.sample, using: encoder).required {
            return try OpenAPIReflection30.genericOpenAPISchemaGuess(for: RawValue.sample, using: encoder).requiredSchemaObject().nullableSchemaObject()
        }
        return try OpenAPIReflection30.genericOpenAPISchemaGuess(for: RawValue.sample, using: encoder)
    }
}

// MARK: - TransformedAttribute
extension TransformedAttribute: OpenAPISchemaType where RawValue: OpenAPISchemaType {
    static public var openAPISchema: JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if !RawValue.openAPISchema.required {
			return RawValue.openAPISchema.requiredSchemaObject().nullableSchemaObject()
		}
		return RawValue.openAPISchema
	}
}

extension TransformedAttribute: RawOpenAPISchemaType where RawValue: RawOpenAPISchemaType {
	static public func rawOpenAPISchema() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.rawOpenAPISchema().required {
			return try RawValue.rawOpenAPISchema().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.rawOpenAPISchema()
	}
}

extension TransformedAttribute: DateOpenAPISchemaType where RawValue: DateOpenAPISchemaType {
	public static func dateOpenAPISchemaGuess(using encoder: JSONEncoder) -> JSONSchema? {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if
			!(RawValue.dateOpenAPISchemaGuess(using: encoder)?.required ?? true) {
			return RawValue.dateOpenAPISchemaGuess(using: encoder)?.requiredSchemaObject().nullableSchemaObject()
		}
		return RawValue.dateOpenAPISchemaGuess(using: encoder)
	}
}

extension TransformedAttribute: AnyRawRepresentable where RawValue: AnyRawRepresentable {

    public static var rawValueType: Any.Type { return RawValue.rawValueType }
}

extension TransformedAttribute: AnyJSONCaseIterable where RawValue: AnyJSONCaseIterable {
	public static func allCases(using encoder: JSONEncoder) -> [AnyCodable] {
		return RawValue.allCases(using: encoder)
	}
}

extension TransformedAttribute: OpenAPIAttributeType where RawValue: Sampleable, RawValue: Encodable {
    public static func attributeOpenAPISchemaGuess(using encoder: JSONEncoder) throws -> JSONSchema {
        // If the RawValue is not required, we actually consider it
        // nullable. To be not required is for the Attribute itself
        // to be optional.
        if try !OpenAPIReflection30.genericOpenAPISchemaGuess(for: RawValue.sample, using: encoder).required {
            return try OpenAPIReflection30.genericOpenAPISchemaGuess(for: RawValue.sample, using: encoder).requiredSchemaObject().nullableSchemaObject()
        }
        return try OpenAPIReflection30.genericOpenAPISchemaGuess(for: RawValue.sample, using: encoder)
    }
}
