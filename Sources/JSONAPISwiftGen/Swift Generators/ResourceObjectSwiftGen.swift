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

        let attributesDecl = try attributesSnippet(contextB: resourceObjectContextB,
                                                   allowPlaceholders: allowPlaceholders)

        let relationships = try relationshipsSnippet(contextB: resourceObjectContextB,
                                                     allowPlaceholders: allowPlaceholders)

        let descriptionTypeName = "\(typeName)Description"

        let identifiedTypealias = Typealias(alias: .init(typeName),
                                            existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                                             specializationReps: [
                                                                                .init(descriptionTypeName),
                                                                                .init(NoMetadata.self),
                                                                                .init(NoLinks.self),
                                                                                .init(String.self)
                                            ])))

        let unidenfitiedTypealias = Typealias(alias: .init("New" + typeName),
                                              existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                                               specializationReps: [
                                                                                .init(descriptionTypeName),
                                                                                .init(NoMetadata.self),
                                                                                .init(NoLinks.self),
                                                                                .init(Unidentified.self)
                                              ])))

        let decls = [
            BlockTypeDecl.enum(typeName: descriptionTypeName,
                               conformances: ["JSONAPI.ResourceObjectDescription"],
                               [
                                typeNameDecl,
                                attributesDecl.attributes,
                                relationships.relationshipsDecl
                                ] + attributesDecl.dependencies),
            identifiedTypealias,
            (identified ? nil : unidenfitiedTypealias) as Decl?, // only include unidentified typealias if identified is false
        ].compactMap { $0 }

        let relationshipStubs = try Set(
            relationships.relationshipJSONTypeNames.map {
                try ResourceObjectStubSwiftGen(jsonAPITypeName: $0)
            }
        )

        return (decls: decls, relationshipStubs: relationshipStubs)
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

        guard let possibleTypeNames = typeNameContextA.allowedValues else {
            let placeholder = swiftPlaceholder(name: "JSON:API type", type: .init(String.self))
            guard allowPlaceholders else {
                throw Error.attributeTypeUnspecified(placeholder: placeholder)
            }
            return placeholder
        }

        guard possibleTypeNames.count == 1,
            let typeNameString = possibleTypeNames.first.flatMap({ $0.value as? String }) else {
                let typeNames = possibleTypeNames
                    .compactMap { $0.value as? String }
                    .map(typeCased)
                    .joined(separator: ", ")
                let placeholder = swiftPlaceholder(name: typeNames, type: .def(.init(name: "Either<\(typeNames)>")))

                guard allowPlaceholders else {
                    throw Error.attributeTypePolymorphismUnsupported(placeholder: placeholder)
                }

                return placeholder
        }

        return typeNameString
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func attributesSnippet(contextB: JSONSchema.ObjectContext,
                                          allowPlaceholders: Bool) throws -> (attributes: Decl, dependencies: [Decl]) {

        let newTypeName = "Attributes"

        guard case let .object(_, attributesContextB)? = contextB.properties[Key.attributes.rawValue] else {
            let noAttributesDecl = Typealias(alias: .init(newTypeName), existingType: .init(NoAttributes.self))
            return (attributes: noAttributesDecl, dependencies: [])
        }

        let attributeDecls: [(Decl, dependencies: [Decl])] = try attributesContextB
            .properties
            .sorted { $0.key < $1.key }
            .map { keyValue in
            return try attributeSnippet(name: keyValue.key,
                                        schema: keyValue.value,
                                        allowPlaceholders: allowPlaceholders)
        }

        let codingKeyDecl = BlockTypeDecl.enum(typeName: "CodingKeys",
                                                conformances: ["CodingKey, Equatable"],
                                                attributesContextB.properties.keys.map(BlockTypeDecl.enumCase))

        let attributesDecl = BlockTypeDecl.struct(typeName: newTypeName,
                                                  conformances: ["JSONAPI.SparsableAttributes"],
                                                  attributeDecls.map { $0.0 } + [codingKeyDecl])

        return (attributes: attributesDecl, dependencies: attributeDecls.flatMap { $0.1 })
    }

    private static func attributeSnippet(name: String,
                                         schema: JSONSchema,
                                         allowPlaceholders: Bool) throws -> (property: Decl, dependencies: [Decl]) {

        let isOmittable = !schema.required
        let isNullable = schema.nullable

        let attributeRawTypeRep: SwiftTypeRep
        let dependencies: [Decl]

        switch schema {
        case .object:
            let structureGen = try StructureSwiftGen(swiftTypeName: typeCased(name),
                                                     structure: schema,
                                                     cascadingConformances: ["Codable", "Equatable"])
            attributeRawTypeRep = .def(.init(name: structureGen.swiftTypeName))
            dependencies = structureGen.decls
        default:
            attributeRawTypeRep = try swiftType(from: schema,
                                                allowPlaceholders: allowPlaceholders,
                                                handleOptionality: false)
            dependencies = []
        }

        let finalAttributeRawTypeRep = isNullable
            ? attributeRawTypeRep.optional
            : attributeRawTypeRep

        let attributePropertyDecl = PropDecl.let(propName: name,
                                                 swiftType: .init(SwiftTypeDef(name: "Attribute",
                                                                               specializationReps: [finalAttributeRawTypeRep],
                                                                               optional: isOmittable)), nil)

        return  (property: attributePropertyDecl, dependencies: dependencies)
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

        case attributeTypeUnspecified(placeholder: String)
        case attributeTypePolymorphismUnsupported(placeholder: String)

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
            case .attributeTypeUnspecified(placeholder: let placeholder):
                return "Encountered an Attribute type that was not specified (no enumerated list of allowed values). With `allowPlaceholders: true`, this type would have been: \(placeholder)."
            case .attributeTypePolymorphismUnsupported(placeholder: let placeholder):
                return "Encountered an Attribute with a polymorphic type. Generation on polymorphic types is not supported. With `allowPlaceholders: true`, this type would have been: \(placeholder)."
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
