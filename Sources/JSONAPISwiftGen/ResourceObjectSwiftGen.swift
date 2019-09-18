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
    public let swiftCode: String
    public let swiftTypeName: String
    public let relationshipStubGenerators: Set<ResourceObjectStubSwiftGen>

    public init(structure: JSONSchema) throws {
        self.structure = structure

        (decls, relationshipStubGenerators) = try ResourceObjectSwiftGen.swiftDecls(from: structure)
        swiftCode = ResourceObjectSwiftGen.swiftCode(from: decls)
        swiftTypeName = decls.compactMap { $0 as? Typealias }.first!.alias.swiftCode
    }

    static func swiftCode(from decls: [Decl]) -> String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
    }

    static func swiftDecls(from structure: JSONSchema)  throws -> (decls: [Decl], relationshipStubs: Set<ResourceObjectStubSwiftGen>) {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        let (typeName, typeNameDecl) = try typeNameSnippet(contextB: resourceObjectContextB)

        let identified = resourceObjectContextB.properties[Key.id.rawValue] != nil

        let attributesDecl = try attributesSnippet(contextB: resourceObjectContextB)

        let relationships = try relationshipsSnippet(contextB: resourceObjectContextB)

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
    private static func typeNameSnippet(contextB: JSONSchema.ObjectContext) throws -> (typeName: String, typeNameDeclCode: Decl) {
        let typeNameString = try typeName(from: contextB)

        return (typeName: typeCased(typeNameString),
                typeNameDeclCode: StaticDecl(.let(propName: "jsonType", swiftType: .init(String.self), .init(value: "\"\(typeNameString)\""))))
    }

    private static func typeName(from resourceIdentifierContext: JSONSchema.ObjectContext) throws -> String {
        guard case let .string(typeNameContextA, _)? = resourceIdentifierContext.properties[Key.type.rawValue] else {
            throw Error.jsonAPITypeNotFound
        }

        if let possibleTypeNames = typeNameContextA.allowedValues,
            possibleTypeNames.count == 1,
            let typeNameString = possibleTypeNames.first.flatMap({ $0.value as? String }) {
            return typeNameString
        } else {
            return swiftPlaceholder(name: "JSON:API type", type: .init(String.self))
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
    private static func relationshipsSnippet(contextB: JSONSchema.ObjectContext) throws -> (relationshipJSONTypeNames: [String], relationshipsDecl: Decl) {

        let newTypeName = "Relationships"

        guard case let .object(_, relationshipsContextB)? = contextB.properties[Key.relationships.rawValue] else {
            return (relationshipJSONTypeNames: [], relationshipsDecl: Typealias(alias: .init(newTypeName), existingType: .init(NoRelationships.self)))
        }

        let relationshipDecls: [(jsonTypeName: String, decl: Decl)] = try relationshipsContextB
            .properties
            .sorted { $0.key < $1.key }
            .map { keyValue in
                return try relationshipSnippet(name: keyValue.key,
                                               schema: keyValue.value)
        }

        let relationshipJSONTypenames = relationshipDecls.map { $0.jsonTypeName }

        let decl = BlockTypeDecl.struct(typeName: newTypeName,
                                        conformances: ["JSONAPI.\(newTypeName)"],
                                        relationshipDecls.map { $0.decl })

        return (relationshipJSONTypeNames: relationshipJSONTypenames,
                relationshipsDecl: decl)
    }

    private static func relationshipSnippet(name: String, schema: JSONSchema) throws -> (jsonTypeName: String, typeNameDeclCode: Decl) {

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

            relatedJSONTypeName = try typeName(from: contextB)

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
                    throw Error.relationshipDataMissingType
            }

            relatedJSONTypeName = try typeName(from: relationshipObjectContext)

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

    private static func typeCased(_ name: String) -> String {
        let words = name.split(whereSeparator: "_-".contains)
        let casedWords = words.map { word -> String in
            let firstChar = word.first?.uppercased() ?? ""
            return String(firstChar + word.dropFirst())
        }
        return casedWords.joined()
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
    enum Error: Swift.Error {
        case rootNotJSONObject

        case jsonAPITypeNotFound

        case relationshipMalformed
        case relationshipMissingDataObject
        case toManyRelationshipCannotBeNullable
        case relationshipDataMissingType
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
