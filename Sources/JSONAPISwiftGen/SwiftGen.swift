//
//  SwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

public struct ResourceObjectSwiftGen: SwiftCodeRepresentable {
    public let structure: JSONSchema
    public let decls: [Decl]
    public let swiftCode: String
    public let swiftTypeName: String

    public init(structure: JSONSchema) throws {
        decls = try ResourceObjectSwiftGen.resourceObjectSwiftDecls(from: structure)
        swiftCode = ResourceObjectSwiftGen.resourceObjectSwiftCode(from: decls)
        swiftTypeName = decls.compactMap { $0 as? Typealias }.first!.alias.swiftCode

        self.structure = structure
    }

    public static func resourceObjectSwiftCode(from decls: [Decl]) -> String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
    }

    public static func resourceObjectSwiftDecls(from structure: JSONSchema)  throws -> [Decl] {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        let (typeName, typeNameDecl) = try typeNameSnippet(contextB: resourceObjectContextB)

        let attributesDecl = try attributesSnippet(contextB: resourceObjectContextB)

        let relationshipsDecl = try relationshipsSnippet(contextB: resourceObjectContextB)

        let descriptionTypeName = "\(typeName)Description"

        return [
            BlockTypeDecl.enum(typeName: descriptionTypeName,
                               conformances: ["JSONAPI.ResourceObjectDescription"],
                               [
                                typeNameDecl,
                                attributesDecl,
                                relationshipsDecl
            ]),
            Typealias(alias: .init(typeName),
                      existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                       specializationReps: [
                                                        .init(descriptionTypeName),
                                                        .init(NoMetadata.self),
                                                        .init(NoLinks.self),
                                                        .init(String.self)
                      ])))
        ]
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
            return placeholder(name: "JSON:API type", type: .init(String.self))
        }
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func attributesSnippet(contextB: JSONSchema.ObjectContext) throws -> Decl {

        let newTypeName = "Attributes"

        guard case let .object(_, attributesContextB)? = contextB.properties[Key.attributes.rawValue] else {
            return Typealias(alias: .init(newTypeName), existingType: .init(NoAttributes.self))
        }

        let attributeDecls: [Decl] = try attributesContextB.properties.map { keyValue in
            return try attributeSnippet(name: keyValue.key,
                                        schema: keyValue.value)
        }

        return BlockTypeDecl.struct(typeName: newTypeName,
                                    conformances: ["JSONAPI.\(newTypeName)"],
                                    attributeDecls)
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
    private static func relationshipsSnippet(contextB: JSONSchema.ObjectContext) throws -> Decl {

        let newTypeName = "Relationships"

        guard case let .object(_, relationshipsContextB)? = contextB.properties[Key.relationships.rawValue] else {
            return Typealias(alias: .init(newTypeName), existingType: .init(NoRelationships.self))
        }

        let relationshipDecls: [Decl] = try relationshipsContextB.properties.map { keyValue in
            return try relationshipSnippet(name: keyValue.key,
                                           schema: keyValue.value)
        }

        return BlockTypeDecl.struct(typeName: newTypeName,
                                    conformances: ["JSONAPI.\(newTypeName)"],
                                    relationshipDecls)
    }

    private static func relationshipSnippet(name: String, schema: JSONSchema) throws -> Decl {

        guard case let .object(_, relationshipContextB) = schema,
            let dataSchema = relationshipContextB.properties[Key.data.rawValue] else {
                throw Error.relationshipMalformed
        }

        let isOmittable = !schema.required
        let isNullable = dataSchema.nullable

        let oneOrManyName: String
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

            let tmpRelTypeRep = try SwiftTypeRep(typeCased(typeName(from: contextB)))

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
            relationshipTypeRep = try SwiftTypeRep(typeCased(typeName(from: relationshipObjectContext)))

        default:
            throw Error.relationshipMalformed
        }

        return PropDecl.let(propName: name,
                            swiftType: .init(SwiftTypeDef(name: oneOrManyName,
                                                          specializationReps: [
                                                            relationshipTypeRep,
                                                            .init(NoMetadata.self),
                                                            .init(NoLinks.self)
                                ], optional: isOmittable)),
                            nil)
    }

    private static func swiftType(from schema: JSONSchema) throws -> SwiftTypeRep {
        switch schema.jsonTypeFormat {
        case nil:
            throw Error.attributeTypeNotFound
        case .boolean(let format)?:
            return SwiftTypeRep(type(of: format).SwiftType.self)
        case .object(let format)?:
            return SwiftTypeRep(placeholder(name: "Swift Type", type: "Any"))
        case .array(let format)?:
            return SwiftTypeRep(placeholder(name: "Swift Type", type: "[Any]"))
        case .number(let format)?:
            return SwiftTypeRep(type(of: format).SwiftType.self)
        case .integer(let format)?:
            return SwiftTypeRep(type(of: format).SwiftType.self)
        case .string(let format)?:
            return SwiftTypeRep(type(of: format).SwiftType.self)
        }
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

        case attributeTypeNotFound

        case relationshipMalformed
        case relationshipMissingDataObject
        case toManyRelationshipCannotBeNullable
        case relationshipDataMissingType
    }
}

private func placeholder(name: String, type: SwiftTypeRep) -> String {
    return "<#T##\(name)##"
        + type.swiftCode
        + "#>"
}
