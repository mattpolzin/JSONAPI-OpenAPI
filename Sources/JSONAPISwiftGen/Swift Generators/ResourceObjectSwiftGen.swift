//
//  ResourceObjectSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/7/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

public protocol ResourceTypeSwiftGenerator: SwiftTypeGenerator {
    var resourceTypeName: String { get }
}

extension ResourceTypeSwiftGenerator {
    public func defines(typeName: String) -> Bool {
        return exportedSwiftTypeNames.contains(typeName)
    }
}

/// A Swift generator that produces code for the types needed
/// by a JSONAPI ResourceObject.
public struct ResourceObjectSwiftGen: JSONSchemaSwiftGenerator, ResourceTypeSwiftGenerator {
    public let structure: DereferencedJSONSchema
    public let decls: [Decl]
    public let resourceTypeName: String
    public let exportedSwiftTypeNames: Set<String>
    public let relatives: Set<Relative>
    public let relationshipStubGenerators: Set<ResourceObjectStubSwiftGen>

    /// A Generator that produces Swift code for a JSONAPI Resource Object type.
    /// - parameters:
    ///     - structure: a JSONSchema describing the entire JSON:API Resource Object.
    ///     - allowPlaceholders: If true (default) then placeholders will be used for the Swift
    ///         types of things the generator cannot determine the type or structure of. If false, the
    ///         generator will throw an error in those situations.
    public init(
        structure: DereferencedJSONSchema,
        allowPlaceholders: Bool = true
    ) throws {
        self.structure = structure

        (decls, relatives, relationshipStubGenerators) = try ResourceObjectSwiftGen.swiftDecls(
            from: structure,
            allowPlaceholders: allowPlaceholders
        )

        let typealiases = decls.compactMap { $0 as? Typealias }

        resourceTypeName = typealiases.first.map { $0.alias.swiftCode }!

        exportedSwiftTypeNames = Set(typealiases.map { $0.alias.swiftCode })
    }

    static func swiftDecls(
        from structure: DereferencedJSONSchema,
        allowPlaceholders: Bool
    )  throws -> (decls: [Decl], relatives: Set<Relative>, relationshipStubs: Set<ResourceObjectStubSwiftGen>) {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        let (typeName, typeNameDecl) = try jsonAPITypeNameSnippet(
            contextB: resourceObjectContextB,
            allowPlaceholders: allowPlaceholders
        )

        let identified = resourceObjectContextB.properties[Key.id.rawValue] != nil

        let attributesDecl = try attributesSnippet(
            contextB: resourceObjectContextB,
            allowPlaceholders: allowPlaceholders
        )

        let relationships = try relationshipsSnippet(
            contextB: resourceObjectContextB,
            allowPlaceholders: allowPlaceholders
        )

        let descriptionTypeName = "\(typeName)Description"

        let identifiedTypealias = Typealias(
            alias: .init(typeName),
            existingType: .init(
                SwiftTypeDef(
                    name: "JSONAPI.ResourceObject",
                    specializationReps: [
                        .init(descriptionTypeName),
                        .init(NoMetadata.self),
                        .init(NoLinks.self),
                        .init(String.self)
                    ]
                )
            )
        )

        let unidenfitiedTypealias = Typealias(
            alias: .init("Unidentified" + typeName),
            existingType: .init(
                SwiftTypeDef(
                    name: "JSONAPI.ResourceObject",
                    specializationReps: [
                        .init(descriptionTypeName),
                        .init(NoMetadata.self),
                        .init(NoLinks.self),
                        .init(Unidentified.self)
                    ]
                )
            )
        )

        let decls = [
            BlockTypeDecl.enum(
                typeName: descriptionTypeName,
                conformances: ["JSONAPI.ResourceObjectDescription"],
                [
                    typeNameDecl,
                    attributesDecl.attributes,
                    relationships.relationshipsDecl
                ] + attributesDecl.dependencies
            ),
            (identified ? nil : unidenfitiedTypealias) as Decl?, // only include unidentified typealias if identified is false
            identifiedTypealias
        ].compactMap { $0 }

        let relationshipStubs = try Set(
            relationships.relatives.map {
                try ResourceObjectStubSwiftGen(jsonAPITypeName: $0.jsonTypeName)
            }
        )

        return (decls: decls, relatives: Set(relationships.relatives), relationshipStubs: relationshipStubs)
    }

    /// Creates a snippet of code that declares the static Swift property
    /// containing the JSON:API type name.
    ///
    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func jsonAPITypeNameSnippet(
        contextB: DereferencedJSONSchema.ObjectContext,
        allowPlaceholders: Bool
    ) throws -> (typeName: String, typeNameDeclCode: Decl) {
        let typeNameString = try jsonAPITypeName(
            from: contextB,
            allowPlaceholders: allowPlaceholders
        )

        return (
            typeName: typeCased(typeNameString),
            typeNameDeclCode: StaticDecl(.let(propName: "jsonType", swiftType: .init(String.self), .init(value: "\"\(typeNameString)\"")))
        )
    }

    /// Get the JSON:API type name generated for this JSON:API type.
    ///
    /// If the JSON:API resource is documented as having
    ///
    ///     type:
    ///         type: string
    ///         enum:
    ///             - widget
    ///
    /// then the JSON:API type name will be "widget".
    ///
    /// If the JSON:API resource is documented as having
    ///
    ///     type:
    ///         type: string
    ///         enum:
    ///             - widget
    ///             - cog
    ///
    /// then the JSON:API type is polymorphic. This is not currently supported so it will
    /// throw an error.
    ///
    /// Similarly, if the JSON:API resource is documented as having
    ///
    ///     type:
    ///         type: string
    ///
    /// then the JSON:API type is unspecified. This is not currently supported so it will
    /// throw an error.
    private static func jsonAPITypeName(
        from resourceIdentifierContext: DereferencedJSONSchema.ObjectContext,
        allowPlaceholders: Bool
    ) throws -> String {
        guard case let .string(typeNameContextA, _)? = resourceIdentifierContext.properties[Key.type.rawValue] else {
            throw Error.jsonAPITypeNotFound
        }

        guard let possibleTypeNames = typeNameContextA.allowedValues else {
            let placeholder = swiftPlaceholder(name: "JSON:API type", type: .init(String.self))
            guard allowPlaceholders else {
                throw Error.jsonAPITypeUnspecified(placeholder: placeholder)
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
                    throw Error.jsonAPITypePolymorphismUnsupported(placeholder: placeholder)
                }

                return placeholder
        }

        return typeNameString
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func attributesSnippet(
        contextB: DereferencedJSONSchema.ObjectContext,
        allowPlaceholders: Bool
    ) throws -> (attributes: Decl, dependencies: [Decl]) {

        let attributeTypeName = "Attributes"

        guard case let .object(_, attributesContextB)? = contextB.properties[Key.attributes.rawValue] else {
            let noAttributesDecl = Typealias(alias: .init(attributeTypeName), existingType: .init(NoAttributes.self))
            return (attributes: noAttributesDecl, dependencies: [])
        }

        let attributeDecls: [(Decl, dependencies: [Decl])] = try attributesContextB
            .properties
            .sorted { $0.key < $1.key }
            .map { keyValue in
            return try attributeSnippet(
                name: propertyCased(keyValue.key),
                schema: keyValue.value,
                allowPlaceholders: allowPlaceholders
                )
        }

        let codingKeyCaseDecls = attributesContextB
            .properties
            .keys
            .map{
                BlockTypeDecl.enumCase(propertyCased($0), stringValue: $0)
        }

        let hasAttributes = codingKeyCaseDecls.count > 0

        let codingKeyDecl = BlockTypeDecl.enum(
            typeName: "CodingKeys",
            conformances: ["String", "CodingKey, Equatable"],
            codingKeyCaseDecls
        )

        let attributesAndCodingKeys = attributeDecls
            .map { $0.0 }
            + (hasAttributes ? [codingKeyDecl] : []) // only include CodingKeys if non-zero count of attributes

        let conformances = hasAttributes
            ? ["JSONAPI.SparsableAttributes"]
            : ["JSONAPI.Attributes"] // only make sparsable if non-zero count of attributes

        let attributesDecl = BlockTypeDecl.struct(
            typeName: attributeTypeName,
            conformances: conformances,
            attributesAndCodingKeys
        )

        return (attributes: attributesDecl, dependencies: attributeDecls.flatMap { $0.1 })
    }

    /// Takes a JSONSchema and attempts to create a single attribute's
    /// code snippet (Decl).
    private static func attributeSnippet(
        name: String,
        schema: DereferencedJSONSchema,
        allowPlaceholders: Bool
    ) throws -> (property: Decl, dependencies: [Decl]) {

        let isOmittable = !schema.required
        let isNullable = schema.nullable

        let attributeRawTypeRep: SwiftTypeRep
        let dependencies: [Decl]

        switch schema {
        case .object, .one:
            let structureGen = try StructureSwiftGen(
                swiftTypeName: typeCased(name),
                structure: schema,
                cascadingConformances: ["Codable", "Equatable"]
            )
            attributeRawTypeRep = .def(.init(name: structureGen.swiftTypeName))
            dependencies = structureGen.decls
        default:
            attributeRawTypeRep = try swiftType(
                from: schema,
                allowPlaceholders: allowPlaceholders,
                handleOptionality: false
            )
            dependencies = []
        }

        let finalAttributeRawTypeRep = isNullable
            ? attributeRawTypeRep.optional
            : attributeRawTypeRep

        let attributePropertyDecl = PropDecl.let(
            propName: name,
            swiftType: .init(
                SwiftTypeDef(
                    name: "Attribute",
                    specializationReps: [finalAttributeRawTypeRep],
                    optional: isOmittable
                )
            ),
            nil
        )

        return  (property: attributePropertyDecl, dependencies: dependencies)
    }

    /// Takes the second context of the root of the JSON Schema for a Resource Object.
    private static func relationshipsSnippet(
        contextB: DereferencedJSONSchema.ObjectContext,
        allowPlaceholders: Bool
    ) throws -> (relatives: [Relative], relationshipsDecl: Decl) {

        let relationshipTypeName = "Relationships"

        guard case let .object(_, relationshipsContextB)? = contextB.properties[Key.relationships.rawValue] else {
            return (relatives: [], relationshipsDecl: Typealias(alias: .init(relationshipTypeName), existingType: .init(NoRelationships.self)))
        }

        let relationshipDecls: [(relative: Relative, decl: Decl)] = try relationshipsContextB
            .properties
            .sorted { $0.key < $1.key }
            .map { keyValue in
                return try relationshipSnippet(
                    name: propertyCased(keyValue.key),
                    schema: keyValue.value,
                    allowPlaceholders: allowPlaceholders
                )
        }

        let codingKeyCaseDecls = relationshipsContextB
            .properties
            .keys
            .map{
                BlockTypeDecl.enumCase(propertyCased($0), stringValue: $0)
        }

        let hasRelationships = codingKeyCaseDecls.count > 0

        let codingKeyDecl = BlockTypeDecl.enum(
            typeName: "CodingKeys",
            conformances: ["String", "CodingKey, Equatable"],
            codingKeyCaseDecls
        )

        let relationshipsAndCodingKeys = relationshipDecls
            .map { $0.decl }
            + (hasRelationships ? [codingKeyDecl] : []) // only include CodingKeys if non-zero count of relationships

        let relatives = relationshipDecls.map { $0.relative }

        let decl = BlockTypeDecl.struct(
            typeName: relationshipTypeName,
            conformances: ["JSONAPI.\(relationshipTypeName)"],
            relationshipsAndCodingKeys
        )

        return (relatives: relatives,
                relationshipsDecl: decl)
    }

    private static func relationshipSnippet(
        name: String,
        schema: DereferencedJSONSchema,
        allowPlaceholders: Bool
    ) throws -> (relative: Relative, typeNameDeclCode: Decl) {

        guard case let .object(_, relationshipContextB) = schema,
            let dataSchema = relationshipContextB.properties[Key.data.rawValue] else {
                throw Error.relationshipMalformed
        }

        let isOmittable = !schema.required
        let isNullable = dataSchema.nullable

        let relationship: Relative.Relationship
        let oneOrManyName: String
        let relatedJSONTypeName: String
        let relatedSwiftTypeName: String
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

            relatedJSONTypeName = try jsonAPITypeName(
                from: contextB,
                allowPlaceholders: allowPlaceholders
            )

            relatedSwiftTypeName = typeCased(relatedJSONTypeName)
            let tmpRelTypeRep = SwiftTypeRep(relatedSwiftTypeName)

            relationshipTypeRep = isNullable
                ? tmpRelTypeRep.optional
                : tmpRelTypeRep

            relationship = .toOne(isNullable || isOmittable ? .optional : .required)

        case .array(_, let contextB):
            guard isNullable == false else {
                throw Error.toManyRelationshipCannotBeNullable
            }
            oneOrManyName = "ToManyRelationship"

            guard let relationshipEntry = contextB.items,
                case let .object(_, relationshipObjectContext) = relationshipEntry else {
                    throw Error.toManyRelationshipNotDefined
            }

            relatedJSONTypeName = try jsonAPITypeName(
                from: relationshipObjectContext,
                allowPlaceholders: allowPlaceholders
            )

            relatedSwiftTypeName = typeCased(relatedJSONTypeName)
            relationshipTypeRep = SwiftTypeRep(relatedSwiftTypeName)

            relationship = .toMany(isOmittable ? .optional : .required)

        default:
            throw Error.relationshipMalformed
        }

        let typeDecl = PropDecl.let(
            propName: name,
            swiftType: .init(
                SwiftTypeDef(
                    name: oneOrManyName,
                    specializationReps: [
                        relationshipTypeRep,
                        .init(NoMetadata.self),
                        .init(NoLinks.self)
                    ], optional: isOmittable
                )
            ),
            nil
        )

        return (
            relative: .init(
                propertyName: name,
                swiftTypeName: relatedSwiftTypeName,
                jsonTypeName: relatedJSONTypeName,
                relationshipType: relationship
            ),
            typeNameDeclCode: typeDecl
        )
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
        case jsonAPITypeUnspecified(placeholder: String)
        case jsonAPITypePolymorphismUnsupported(placeholder: String)

        case relationshipMalformed
        case relationshipMissingDataObject
        case toManyRelationshipCannotBeNullable
        case toManyRelationshipNotDefined

        public var debugDescription: String {
            switch self {
            case .rootNotJSONObject:
                return "Tried to parse a JSON:API Resource Object schema that did not have a JSON Schema 'object' type at its root."
            case .jsonAPITypeNotFound:
                return "Tried to parse a JSON:API Resource Object schema that did not have a JSON:API 'type' property."
            case .jsonAPITypeUnspecified(placeholder: let placeholder):
                return "Encountered an JSON:API type that was not specified. Make sure that your resource `type` properties have `enum` declarations that define the allowed values for the JSON:API type of the given resource. With `allowPlaceholders: true`, this type would have been: \(placeholder)."
            case .jsonAPITypePolymorphismUnsupported(placeholder: let placeholder):
                return "Encountered a resource with a polymorphic type. Generation on polymorphic types is not supported. Make sure that your resource `type` properties have `enum` declarations with only one allowed JSON:API type value. With `allowPlaceholders: true`, this type would have been: \(placeholder)."
            case .relationshipMalformed:
                return "Encountered an unexpected schema when parsing a JSON:API Resource Object's Relationships Object."
            case .relationshipMissingDataObject:
                return "Tried to parse JSON:API a Relationship schema that did not have either a 'data' object or 'data' array."
            case .toManyRelationshipCannotBeNullable:
                return "Encountered a nullable to-many JSON:API Relationship in schema. This is not allowed by the spec."
            case .toManyRelationshipNotDefined:
                return "Tried to parse a to-many JSON:API Relationship schema and did not find an 'items' property defining the Relationship type/id."
            }
        }
    }
}

extension ResourceObjectSwiftGen: Hashable {
    public static func == (lhs: ResourceObjectSwiftGen, rhs: ResourceObjectSwiftGen) -> Bool {
        return lhs.resourceTypeName == rhs.resourceTypeName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(resourceTypeName)
    }
}

public struct Relative: Hashable {
    public let propertyName: String
    public let swiftTypeName: String
    public let jsonTypeName: String
    public let relationshipType: Relationship

    public enum Relationship: Hashable {
        case toOne(Optionality)
        case toMany(Optionality)

        public enum Optionality: Hashable {
            case required
            case optional
        }
    }
}
