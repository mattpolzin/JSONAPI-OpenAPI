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

extension ToOneRelationship: OpenAPINodeType {
	// NOTE: const for json `type` not supported by OpenAPI 3.0
	//		Will use "enum" with one possible value for now.

	// TODO: metadata & links
	static public func openAPINode() throws -> JSONSchema {
		let nullable = Identifiable.self is _Optional.Type
		return .object(.init(format: .generic,
							 required: true),
					   .init(properties: [
						"data": ToOneRelationship.relationshipNode(nullable: nullable, jsonType: Identifiable.jsonType)
						]))
	}
}

extension ToManyRelationship: OpenAPINodeType {
	// NOTE: const for json `type` not supported by OpenAPI 3.0
	//		Will use "enum" with one possible value for now.

	// TODO: metadata & links
	static public func openAPINode() throws -> JSONSchema {
		return .object(.init(format: .generic,
							 required: true),
					   .init(properties: [
						"data": .array(.init(format: .generic,
											 required: true),
									   .init(items: ToManyRelationship.relationshipNode(nullable: false, jsonType: Relatable.jsonType)))
						]))
	}
}

extension ResourceObject: OpenAPIEncodedNodeType where Description.Attributes: Sampleable, Description.Relationships: Sampleable {
	public static func openAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
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
			: try Description.Attributes.genericOpenAPINode(using: encoder)

		let attributesProperty = attributesNode.map { ("attributes", $0) }

		let relationshipsNode: JSONSchema? = Description.Relationships.self == NoRelationships.self
			? nil
			: try Description.Relationships.genericOpenAPINode(using: encoder)

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

extension Optional: OpenAPIEncodedNodeType where Wrapped: OpenAPIEncodedNodeType {
    public static func openAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
        return try Wrapped.openAPINode(using: encoder).nullableSchemaObject()
    }
}

extension SingleResourceBody: OpenAPIEncodedNodeType where Entity: OpenAPIEncodedNodeType {
	public static func openAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
		return try Entity.openAPINode(using: encoder)
	}
}

extension ManyResourceBody: OpenAPIEncodedNodeType where Entity: OpenAPIEncodedNodeType {
	public static func openAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
		return .array(.init(format: .generic,
							required: true),
					  .init(items: try Entity.openAPINode(using: encoder)))
	}
}

extension Document: OpenAPIEncodedNodeType where PrimaryResourceBody: OpenAPIEncodedNodeType, IncludeType: OpenAPIEncodedNodeType {
	public static func openAPINode(using encoder: JSONEncoder) throws -> JSONSchema {
		// TODO: metadata, links, api description, errors
		// TODO: represent data and errors as the two distinct possible outcomes

		let primaryDataNode: JSONSchema? = try PrimaryResourceBody.openAPINode(using: encoder)

		let primaryDataProperty = primaryDataNode.map { ("data", $0) }

		let includeNode: JSONSchema?
		do {
			includeNode = try Includes<Include>.openAPINode(using: encoder)
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

		return .object(.init(format: .generic,
							 required: true),
					   .init(properties: propertiesDict))
	}
}
