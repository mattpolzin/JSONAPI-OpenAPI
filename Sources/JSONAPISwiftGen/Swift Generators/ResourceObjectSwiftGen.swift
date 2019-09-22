//
//  ResourceObjectSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/7/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

public struct ResourceObjectSwiftGen: JSONSchemaSwiftGenerator, TypedSwiftGenerator {
    public let structure: JSONSchema
    public let decls: [Decl]
    public let swiftTypeName: String
    public let relationshipStubGenerators: Set<ResourceObjectStubSwiftGen>

    /// A Generator that produces Swift code for a JSONAPI Resource Object type.
    /// - parameters:
    ///     - structure: a JSONSchema describing the entire JSON:API Resource Object.
    ///     - allowPlaceholders: If true (default) then placeholders will be used for the Swift
    ///         types of things the generator cannot determine the type or structure of. If false, the
    ///         generator will throw an error in those situations.
    public init(structure: JSONSchema,
                allowPlaceholders: Bool = true) throws {
        self.structure = structure

        (decls, relationshipStubGenerators) = try ResourceObjectSwiftGen.swiftDecls(from: structure,
                                                                                    allowPlaceholders: allowPlaceholders)
        swiftTypeName = decls.compactMap { $0 as? Typealias }.first!.alias.swiftCode
    }

    static func swiftDecls(from structure: JSONSchema,
                           allowPlaceholders: Bool)  throws -> (decls: [Decl], relationshipStubs: Set<ResourceObjectStubSwiftGen>) {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        let (typeName, typeNameDecl) = try typeNameSnippet(contextB: resourceObjectContextB,
                                                           allowPlaceholders: allowPlaceholders)

        let identified = resourceObjectContextB.properties[Key.id.rawValue] != nil

        let attributesDecl = try attributesSnippet(contextB: resourceObjectContextB)

        let relationships = try relationshipsSnippet(contextB: resourceObjectContextB,
                                                     allowPlaceholders: allowPlaceholders)

        let descriptionTypeName = "\(typeName)Description"

        return (decls: [
            BlockTypeDecl.enum(typeName: descriptionTypeName,
                               conformances: ["JSONAPI.ResourceObjectDescription"],
                               [
                                typeNameDecl,
                                attributesDecl,
                                relationships.relationshipsDecl
            ]),
            Typealias(alias: .init(typeName),
                      existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                       specializationReps: [
                                                        .init(descriptionTypeName),
                                                        .init(NoMetadata.self),
                                                        .init(NoLinks.self),
                                                        identified ? .init(String.self) : .init(Unidentified.self)
                      ])))
            ],
                relationshipStubs: try Set(relationships.relationshipJSONTypeNames.map {
                    try ResourceObjectStubSwiftGen(jsonAPITypeName: $0)
                }))
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func typeNameSnippet(contextB: JSONSchema.ObjectContext,
                                        allowPlaceholders: Bool) throws -> (typeName: String, typeNameDeclCode: Decl) {
        let typeNameString = try typeName(from: contextB,
                                          allowPlaceholders: allowPlaceholders)

        return (typeName: typeCased(typeNameString),
                typeNameDeclCode: StaticDecl(.let(propName: "jsonType", swiftType: .init(String.self), .init(value: "\"\(typeNameString)\""))))
    }

    private static func typeName(from resourceIdentifierContext: JSONSchema.ObjectContext,
                                 allowPlaceholders: Bool) throws -> String {
        guard case let .string(typeNameContextA, _)? = resourceIdentifierContext.properties[Key.type.rawValue] else {
            throw Error.jsonAPITypeNotFound
        }

        if let possibleTypeNames = typeNameContextA.allowedValues,
            possibleTypeNames.count == 1,
            let typeNameString = possibleTypeNames.first.flatMap({ $0.value as? String }) {
            return typeNameString
        } else {
            let placeholder = swiftPlaceholder(name: "JSON:API type", type: .init(String.self))
            guard allowPlaceholders else {
                throw Error.typeCouldNotBeDetermined(placeholder: placeholder)
            }
            return placeholder
        }
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func attributesSnippet(contextB: JSONSchema.ObjectContext) throws -> Decl {

        let newTypeName = "Attributes"

        guard case let .object(_, attributesContextB)? = contextB.properties[Key.attributes.rawValue] else {
            return Typealias(alias: .init(newTypeName), existingType: .init(NoAttributes.self))
        }

        let attributeDecls: [Decl] = try attributesContextB
            .properties
            .sorted { $0.key < $1.key }
            .map { keyValue in
            return try attributeSnippet(name: keyValue.key,
                                        schema: keyValue.value)
        }

        let codingKeyDecl = BlockTypeDecl.enum(typeName: "CodingKeys",
                                                conformances: ["CodingKey, Equatable"],
                                                attributesContextB.properties.keys.map(BlockTypeDecl.enumCase))

        return BlockTypeDecl.struct(typeName: newTypeName,
                                    conformances: ["JSONAPI.SparsableAttributes"],
                                    attributeDecls + [codingKeyDecl])
    }

    private static func attributeSnippet(name: String, schema: JSONSchema) throws -> Decl {

        let isOmittable = !schema.required
        let isNullable = schema.nullable

        let attributeRawTypeRep = try swiftType(from: schema)

        let finalAttributeRawTypeRep = isNullable
            ? attributeRawTypeRep.optional
            : attributeRawTypeRep

        return PropDecl.let(propName: name,
                            swiftType: .init(SwiftTypeDef(name: "Attribute",
                                                          specializationReps: [finalAttributeRawTypeRep],
                                                          optional: isOmittable)), nil)
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func relationshipsSnippet(contextB: JSONSchema.ObjectContext,
                                             allowPlaceholders: Bool) throws -> (relationshipJSONTypeNames: [String], relationshipsDecl: Decl) {

        let newTypeName = "Relationships"

        guard case let .object(_, relationshipsContextB)? = contextB.properties[Key.relationships.rawValue] else {
            return (relationshipJSONTypeNames: [], relationshipsDecl: Typealias(alias: .init(newTypeName), existingType: .init(NoRelationships.self)))
        }

        let relationshipDecls: [(jsonTypeName: String, decl: Decl)] = try relationshipsContextB
            .properties
            .sorted { $0.key < $1.key }
            .map { keyValue in
                return try relationshipSnippet(name: keyValue.key,
                                               schema: keyValue.value,
                                               allowPlaceholders: allowPlaceholders)
        }

        let relationshipJSONTypenames = relationshipDecls.map { $0.jsonTypeName }

        let decl = BlockTypeDecl.struct(typeName: newTypeName,
                                        conformances: ["JSONAPI.\(newTypeName)"],
                                        relationshipDecls.map { $0.decl })

        return (relationshipJSONTypeNames: relationshipJSONTypenames,
                relationshipsDecl: decl)
    }

    private static func relationshipSnippet(name: String,
                                            schema: JSONSchema,
                                            allowPlaceholders: Bool) throws -> (jsonTypeName: String, typeNameDeclCode: Decl) {

        guard case let .object(_, relationshipContextB) = schema,
            let dataSchema = relationshipContextB.properties[Key.data.rawValue] else {
                throw Error.relationshipMalformed
        }

        let isOmittable = !schema.required
        let isNullable = dataSchema.nullable

        let oneOrManyName: String
        let relatedJSONTypeName: String
        let relationshipTypeRep: SwiftTypeRep
        switch dataSchema {
        case .boolean,
             .number,
             .integer,
             .string:
            throw
                Error.relationshipMissingDataObject
        case .object(_, let contextB):
            oneOrManyName = "ToOneRelationship"

            relatedJSONTypeName = try typeName(from: contextB,
                                               allowPlaceholders: allowPlaceholders)

            let tmpRelTypeRep = SwiftTypeRep(typeCased(relatedJSONTypeName))

            relationshipTypeRep = isNullable
                ? tmpRelTypeRep.optional
                : tmpRelTypeRep

        case .array(_, let contextB):
            guard isNullable == false else {
                throw Error.toManyRelationshipCannotBeNullable
            }
            oneOrManyName = "ToManyRelationship"

            guard let relationshipEntry = contextB.items,
                case let .object(_, relationshipObjectContext) = relationshipEntry else {
                    throw Error.toManyRelationshipNotDefined
            }

            relatedJSONTypeName = try typeName(from: relationshipObjectContext,
                                               allowPlaceholders: allowPlaceholders)

            relationshipTypeRep = SwiftTypeRep(typeCased(relatedJSONTypeName))

        default:
            throw Error.relationshipMalformed
        }

        let typeDecl = PropDecl.let(propName: name,
                                    swiftType: .init(SwiftTypeDef(name: oneOrManyName,
                                                                  specializationReps: [
                                                                    relationshipTypeRep,
                                                                    .init(NoMetadata.self),
                                                                    .init(NoLinks.self)
                                    ], optional: isOmittable)),
                                    nil)

        return (jsonTypeName: relatedJSONTypeName,
                typeNameDeclCode: typeDecl)

    }
}

private extension ResourceObjectSwiftGen {
    enum Key: String {
        case type
        case id
        case attributes
        case relationships
        case data
    }
}

public extension ResourceObjectSwiftGen {
    enum Error: Swift.Error, CustomDebugStringConvertible {
        case rootNotJSONObject

        case jsonAPITypeNotFound

        case relationshipMalformed
        case relationshipMissingDataObject
        case toManyRelationshipCannotBeNullable
        case toManyRelationshipNotDefined

        case typeCouldNotBeDetermined(placeholder: String)

        public var debugDescription: String {
            switch self {
            case .rootNotJSONObject:
                return "Tried to parse a JSON:API Resource Object schema that did not have a JSON Schema 'object' type at its root."
            case .jsonAPITypeNotFound:
                return "Tried to parse a JSON:API Resource Object schema that did not have a JSON:API 'type' property."
            case .relationshipMalformed:
                return "Encountered an unexpected schema when parsing a JSON:API Resource Object's Relationships Object."
            case .relationshipMissingDataObject:
                return "Tried to parse JSON:API a Relationship schema that did not have either a 'data' object or 'data' array."
            case .toManyRelationshipCannotBeNullable:
                return "Encountered a nullable to-many JSON:API Relationship in schema. This is not allowed by the spec."
            case .toManyRelationshipNotDefined:
                return "Tried to parse a to-many JSON:API Relationship schema and did not find an 'items' property defining the Relationship type/id."
            case .typeCouldNotBeDetermined(placeholder: let placeholder):
                return "Encountered a type that could not be determined. This may have been a type with no easy Swift analog or a structure that could not be turned into a Swift type. With `allowPlaceholders: true`, this type would have been: \(placeholder)"
            }
        }
    }
}

extension ResourceObjectSwiftGen: Hashable {
    public static func == (lhs: ResourceObjectSwiftGen, rhs: ResourceObjectSwiftGen) -> Bool {
        return lhs.swiftTypeName == rhs.swiftTypeName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(swiftTypeName)
    }
}
