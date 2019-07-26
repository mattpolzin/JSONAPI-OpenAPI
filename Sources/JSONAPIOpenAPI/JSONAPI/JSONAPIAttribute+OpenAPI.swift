//
//  JSONAPIAttribute+OpenAPI.swift
//  JSONAPIOpenAPI
//
//  Created by Mathew Polzin on 1/28/19.
//

import JSONAPI
import OpenAPIKit
import Foundation
import AnyCodable

private protocol _Optional {}
extension Optional: _Optional {}

private protocol Wrapper {
	associatedtype Wrapped
}
extension Optional: Wrapper {}

extension AnyJSONCaseIterable {
    /// Given an array of Codable values, retrieve an array of AnyCodables.
    static func allCases<T: Codable>(from input: [T], using encoder: JSONEncoder) throws -> [AnyCodable] {
        if let alreadyGoodToGo = input as? [AnyCodable] {
            return alreadyGoodToGo
        }

        // The following is messy, but it does get us the intended result:
        // Given any array of things that can be encoded, we want
        // to map to an array of AnyCodable so we can store later. We need to
        // muck with JSONSerialization because something like an `enum` may
        // very well be encoded as a string, and therefore representable
        // by AnyCodable, but AnyCodable wants it to actually BE a String
        // upon initialization.
        guard let arrayOfCodables = try JSONSerialization.jsonObject(with: encoder.encode(input), options: []) as? [Any] else {
            throw OpenAPICodableError.allCasesArrayNotCodable
        }
        return arrayOfCodables.map(AnyCodable.init)
    }
}

// MARK: Attribute
extension Attribute: OpenAPINodeType where RawValue: OpenAPINodeType {
	static public func openAPINode() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.openAPINode().required {
			return try RawValue.openAPINode().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.openAPINode()
	}
}

extension Attribute: RawOpenAPINodeType where RawValue: RawRepresentable, RawValue.RawValue: OpenAPINodeType {
	static public func rawOpenAPINode() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.RawValue.openAPINode().required {
			return try RawValue.RawValue.openAPINode().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.RawValue.openAPINode()
	}
}

extension Attribute: WrappedRawOpenAPIType where RawValue: RawOpenAPINodeType {
	public static func wrappedOpenAPINode() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.rawOpenAPINode().required {
			return try RawValue.rawOpenAPINode().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.rawOpenAPINode()
	}
}

extension Attribute: GenericOpenAPINodeType where RawValue: GenericOpenAPINodeType {
	public static func genericOpenAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.genericOpenAPINode(using: encoder).required {
			return try RawValue.genericOpenAPINode(using: encoder).requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.genericOpenAPINode(using: encoder)
	}
}

extension Attribute: DateOpenAPINodeType where RawValue: DateOpenAPINodeType {
	public static func dateOpenAPINodeGuess(using encoder: JSONEncoder) -> JSONSchema? {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if
			!(RawValue.dateOpenAPINodeGuess(using: encoder)?.required ?? true) {
			return RawValue.dateOpenAPINodeGuess(using: encoder)?.requiredSchemaObject().nullableSchemaObject()
		}
		return RawValue.dateOpenAPINodeGuess(using: encoder)
	}
}

extension Attribute: AnyJSONCaseIterable where RawValue: CaseIterable, RawValue: Codable {
	public static func allCases(using encoder: JSONEncoder) -> [AnyCodable] {
		return (try? allCases(from: Array(RawValue.allCases), using: encoder)) ?? []
	}
}

extension Attribute: AnyWrappedJSONCaseIterable where RawValue: AnyJSONCaseIterable {
	public static func allCases(using encoder: JSONEncoder) -> [AnyCodable] {
		return RawValue.allCases(using: encoder)
	}
}

// MARK: - TransformedAttribute
extension TransformedAttribute: OpenAPINodeType where RawValue: OpenAPINodeType {
	static public func openAPINode() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.openAPINode().required {
			return try RawValue.openAPINode().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.openAPINode()
	}
}

extension TransformedAttribute: RawOpenAPINodeType where RawValue: RawRepresentable, RawValue.RawValue: OpenAPINodeType {
	static public func rawOpenAPINode() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.RawValue.openAPINode().required {
			return try RawValue.RawValue.openAPINode().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.RawValue.openAPINode()
	}
}

extension TransformedAttribute: WrappedRawOpenAPIType where RawValue: RawOpenAPINodeType {
	public static func wrappedOpenAPINode() throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.rawOpenAPINode().required {
			return try RawValue.rawOpenAPINode().requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.rawOpenAPINode()
	}
}

extension TransformedAttribute: GenericOpenAPINodeType where RawValue: GenericOpenAPINodeType {
	public static func genericOpenAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if try !RawValue.genericOpenAPINode(using: encoder).required {
			return try RawValue.genericOpenAPINode(using: encoder).requiredSchemaObject().nullableSchemaObject()
		}
		return try RawValue.genericOpenAPINode(using: encoder)
	}
}

extension TransformedAttribute: DateOpenAPINodeType where RawValue: DateOpenAPINodeType {
	public static func dateOpenAPINodeGuess(using encoder: JSONEncoder) -> JSONSchema? {
		// If the RawValue is not required, we actually consider it
		// nullable. To be not required is for the Attribute itself
		// to be optional.
		if
			!(RawValue.dateOpenAPINodeGuess(using: encoder)?.required ?? true) {
			return RawValue.dateOpenAPINodeGuess(using: encoder)?.requiredSchemaObject().nullableSchemaObject()
		}
		return RawValue.dateOpenAPINodeGuess(using: encoder)
	}
}

extension TransformedAttribute: AnyJSONCaseIterable where RawValue: CaseIterable, RawValue: Codable {
	public static func allCases(using encoder: JSONEncoder) -> [AnyCodable] {
		return (try? allCases(from: Array(RawValue.allCases), using: encoder)) ?? []
	}
}

extension TransformedAttribute: AnyWrappedJSONCaseIterable where RawValue: AnyJSONCaseIterable {
	public static func allCases(using encoder: JSONEncoder) -> [AnyCodable] {
		return RawValue.allCases(using: encoder)
	}
}
