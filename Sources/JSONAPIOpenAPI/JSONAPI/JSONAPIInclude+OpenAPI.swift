//
//  JSONAPIInclude+OpenAPI.swift
//  JSONAPIOpenAPI
//
//  Created by Mathew Polzin on 1/22/19.
//

import JSONAPI
import OpenAPIKit
import OpenAPIReflection
import Foundation

extension Includes: OpenAPIEncodedSchemaType where I: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		let includeNode = try I.openAPISchema(using: encoder)

		return .array(.init(format: .generic,
							required: true),
					  .init(items: includeNode,
							uniqueItems: true))
	}
}

extension Include0: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        throw OpenAPI.TypeError.invalidNode
	}
}

extension Include1: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try A.openAPISchema(using: encoder)
	}
}

extension Include2: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder)
		])
	}
}

extension Include3: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder)
			])
	}
}

extension Include4: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder),
			D.openAPISchema(using: encoder)
			])
	}
}

extension Include5: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder),
			D.openAPISchema(using: encoder),
			E.openAPISchema(using: encoder)
			])
	}
}

extension Include6: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType, F: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder),
			D.openAPISchema(using: encoder),
			E.openAPISchema(using: encoder),
			F.openAPISchema(using: encoder)
			])
	}
}

extension Include7: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType, F: OpenAPIEncodedSchemaType, G: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder),
			D.openAPISchema(using: encoder),
			E.openAPISchema(using: encoder),
			F.openAPISchema(using: encoder),
			G.openAPISchema(using: encoder)
			])
	}
}

extension Include8: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType, F: OpenAPIEncodedSchemaType, G: OpenAPIEncodedSchemaType, H: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder),
			D.openAPISchema(using: encoder),
			E.openAPISchema(using: encoder),
			F.openAPISchema(using: encoder),
			G.openAPISchema(using: encoder),
			H.openAPISchema(using: encoder)
			])
	}
}

extension Include9: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType, F: OpenAPIEncodedSchemaType, G: OpenAPIEncodedSchemaType, H: OpenAPIEncodedSchemaType, I: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try .one(of: [
			A.openAPISchema(using: encoder),
			B.openAPISchema(using: encoder),
			C.openAPISchema(using: encoder),
			D.openAPISchema(using: encoder),
			E.openAPISchema(using: encoder),
			F.openAPISchema(using: encoder),
			G.openAPISchema(using: encoder),
			H.openAPISchema(using: encoder),
			I.openAPISchema(using: encoder)
			])
	}
}

extension Include10: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType, F: OpenAPIEncodedSchemaType, G: OpenAPIEncodedSchemaType, H: OpenAPIEncodedSchemaType, I: OpenAPIEncodedSchemaType, J: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try .one(of: [
            A.openAPISchema(using: encoder),
            B.openAPISchema(using: encoder),
            C.openAPISchema(using: encoder),
            D.openAPISchema(using: encoder),
            E.openAPISchema(using: encoder),
            F.openAPISchema(using: encoder),
            G.openAPISchema(using: encoder),
            H.openAPISchema(using: encoder),
            I.openAPISchema(using: encoder),
            J.openAPISchema(using: encoder)
        ])
    }
}

extension Include11: OpenAPIEncodedSchemaType where A: OpenAPIEncodedSchemaType, B: OpenAPIEncodedSchemaType, C: OpenAPIEncodedSchemaType, D: OpenAPIEncodedSchemaType, E: OpenAPIEncodedSchemaType, F: OpenAPIEncodedSchemaType, G: OpenAPIEncodedSchemaType, H: OpenAPIEncodedSchemaType, I: OpenAPIEncodedSchemaType, J: OpenAPIEncodedSchemaType, K: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try .one(of: [
            A.openAPISchema(using: encoder),
            B.openAPISchema(using: encoder),
            C.openAPISchema(using: encoder),
            D.openAPISchema(using: encoder),
            E.openAPISchema(using: encoder),
            F.openAPISchema(using: encoder),
            G.openAPISchema(using: encoder),
            H.openAPISchema(using: encoder),
            I.openAPISchema(using: encoder),
            J.openAPISchema(using: encoder),
            K.openAPISchema(using: encoder)
        ])
    }
}
