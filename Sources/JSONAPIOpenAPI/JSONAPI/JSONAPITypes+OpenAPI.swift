//
//  JSONAPIOpenAPITypes.swift
//  JSONAPIOpenAPI
//
//  Created by Mathew Polzin on 1/13/19.
//

import JSONAPI
import OpenAPIKit
import Foundation
import AnyCodable
import Sampleable

private protocol _Optional {}
extension Optional: _Optional {}

private protocol Wrapper {
	associatedtype Wrapped
}
extension Optional: Wrapper {}

extension RelationshipType {
	static func relationshipNode(nullable: Bool, jsonType: String) -> JSONSchema {
		let propertiesDict: [String: JSONSchema] = [
			"id": .string(.init(format: .generic,
								required: true),
						  .init()),
			"type": .string(.init(format: .generic,
								  required: true,
								  allowedValues: [.init(jsonType)]),
							.init())
		]

		return .object(.init(format: .generic,
							 required: true,
							 nullable: nullable),
					   .init(properties: propertiesDict))
	}
}

extension ToOneRelationship: OpenAPISchemaType {
	// NOTE: const for json `type` not supported by OpenAPI 3.0
	//		Will use "enum" with one possible value for now.

	// TODO: metadata & links
	static public func openAPISchema() throws -> JSONSchema {
		let nullable = Identifiable.self is _Optional.Type
		return .object(.init(format: .generic,
							 required: true),
					   .init(properties: [
						"data": ToOneRelationship.relationshipNode(nullable: nullable, jsonType: Identifiable.jsonType)
						]))
	}
}

extension ToManyRelationship: OpenAPISchemaType {
	// NOTE: const for json `type` not supported by OpenAPI 3.0
	//		Will use "enum" with one possible value for now.

	// TODO: metadata & links
	static public func openAPISchema() throws -> JSONSchema {
		return .object(.init(format: .generic,
							 required: true),
					   .init(properties: [
						"data": .array(.init(format: .generic,
											 required: true),
									   .init(items: ToManyRelationship.relationshipNode(nullable: false, jsonType: Relatable.jsonType)))
						]))
	}
}

extension ResourceObject: OpenAPIEncodedSchemaType where Description.Attributes: Sampleable, Description.Relationships: Sampleable {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		// NOTE: const for json `type` not supported by OpenAPI 3.0
		//		Will use "enum" with one possible value for now.

		// TODO: metadata, links

		let idNode: JSONSchema? = Id.RawType.self != Unidentified.self
			? JSONSchema.string(.init(format: .generic,
									required: true),
							  .init())
			: nil
		let idProperty = idNode.map { ("id", $0) }

		let typeNode = JSONSchema.string(.init(format: .generic,
											 required: true,
											 allowedValues: [.init(ResourceObject.jsonType)]),
									   .init())
		let typeProperty = ("type", typeNode)

		let attributesNode: JSONSchema? = Description.Attributes.self == NoAttributes.self
			? nil
			: try Description.Attributes.genericOpenAPISchemaGuess(using: encoder)

		let attributesProperty = attributesNode.map { ("attributes", $0) }

		let relationshipsNode: JSONSchema? = Description.Relationships.self == NoRelationships.self
			? nil
			: try Description.Relationships.genericOpenAPISchemaGuess(using: encoder)

		let relationshipsProperty = relationshipsNode.map { ("relationships", $0) }

		let propertiesDict = Dictionary([
			idProperty,
			typeProperty,
			attributesProperty,
			relationshipsProperty
			].compactMap { $0 }) { _, value in value }

		return .object(.init(format: .generic,
							 required: true),
					   .init(properties: propertiesDict))
	}
}

extension Optional: OpenAPIEncodedSchemaType where Wrapped: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try Wrapped.openAPISchema(using: encoder).nullableSchemaObject()
    }
}

extension SingleResourceBody: OpenAPIEncodedSchemaType where PrimaryResource: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return try PrimaryResource.openAPISchema(using: encoder)
	}
}

extension ManyResourceBody: OpenAPIEncodedSchemaType where PrimaryResource: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		return .array(.init(format: .generic,
							required: true),
					  .init(items: try PrimaryResource.openAPISchema(using: encoder)))
	}
}

extension BasicJSONAPIErrorPayload: OpenAPIEncodedSchemaType where IdType: OpenAPISchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return .object(
            properties: [
                "id": try IdType.openAPISchema().optionalSchemaObject(),
                "status": .string(required: false),
                "code": .string(required: false),
                "title": .string(required: false),
                "detail": .string(required: false),
                "source": .object(
                    required: false,
                    properties: [
                        "pointer": .string(required: false),
                        "parameter": .string(required: false)
                    ]
                )
            ]
        )
    }
}

extension GenericJSONAPIError: OpenAPIEncodedSchemaType where ErrorPayload: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return try ErrorPayload.openAPISchema(using: encoder)
    }
}

extension UnknownJSONAPIError: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        return .string(allowedValues: "unknown")
    }
}

extension Document: OpenAPIEncodedSchemaType where PrimaryResourceBody: OpenAPIEncodedSchemaType, IncludeType: OpenAPIEncodedSchemaType, Error: OpenAPIEncodedSchemaType {
	public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
		// TODO: metadata, links, api description, errors
		// TODO: represent data and errors as the two distinct possible outcomes

        let success = try Self.SuccessDocument.openAPISchema(using: encoder)
        let error = try Self.ErrorDocument.openAPISchema(using: encoder)

        return .one(of: [
            success,
            error
        ])
	}
}

extension Document.SuccessDocument: OpenAPIEncodedSchemaType where PrimaryResourceBody: OpenAPIEncodedSchemaType, IncludeType: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        // TODO: metadata, links, api description

        let primaryDataNode: JSONSchema = try PrimaryResourceBody.openAPISchema(using: encoder)

        let primaryDataProperty = ("data", primaryDataNode)

        let includeNode: JSONSchema?
        do {
            includeNode = try Includes<IncludeType>.openAPISchema(using: encoder)
        } catch let err as OpenAPITypeError {
            guard case .invalidNode = err else {
                throw err
            }
            includeNode = nil
        }

        let includeProperty = includeNode.map { ("included", $0) }

        let propertiesDict = Dictionary([
            primaryDataProperty,
            includeProperty
            ].compactMap { $0 }) { _, value in value }

        return .object(
            properties: propertiesDict
        )
    }
}

extension Document.ErrorDocument: OpenAPIEncodedSchemaType where Error: OpenAPIEncodedSchemaType {
    public static func openAPISchema(using encoder: JSONEncoder) throws -> JSONSchema {
        // TODO: metadata, links, api description

        let errorNode: JSONSchema = try Error.openAPISchema(using: encoder)

        let errorsArray = JSONSchema.array(
            items: errorNode
        )

        return .object(
            properties: [
                "errors": errorsArray
            ]
        )
    }
}
