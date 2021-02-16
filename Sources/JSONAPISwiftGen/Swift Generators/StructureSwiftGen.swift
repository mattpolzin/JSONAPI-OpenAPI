//
//  StructureSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/27/19.
//

import Foundation
import OpenAPIKit

/// Given some JSON Schema, attempt to generate Swift code for
/// a `struct` that is capable of parsing data adhering to the schema.
public struct StructureSwiftGen: JSONSchemaSwiftGenerator {
    public let structure: DereferencedJSONSchema
    public let decls: [Decl]
    public let swiftTypeName: String

    /// Create a Swift code generator for a JSON Schema structure.
    /// - parameters:
    ///     - swiftTypeName: The type name for the structure created.
    ///     - structure: The JSON Schema structure for which to create a Swift type.
    ///     - cascadingConformances: Conformances to apply to all child structures
    ///         created.
    ///     - rootConformances: Conformances to only apply to the root structure. Note
    ///         if specified, rootConformances will take the place of cascading conformances
    ///         for the root object. If not specified, cascading conformances will be used on
    ///         the root object and all children.
    public init(
        swiftTypeName: String,
        structure: DereferencedJSONSchema,
        cascadingConformances: [String] = [],
        rootConformances: [String]? = nil
    ) throws {
        let typeName: String
        if reservedTypeNames.contains(swiftTypeName) {
            typeName = "Gen" + swiftTypeName
        } else {
            typeName = swiftTypeName
        }

        self.swiftTypeName = typeName
        self.structure = structure

        switch structure {
        case .object(_, let context):
            decls = [
                try StructureSwiftGen.structure(
                    named: typeName,
                    forObject: context,
                    cascadingConformances: cascadingConformances,
                    rootConformances: rootConformances
                )
            ]
        case .one(of: let schemas, core: _):
            let poly = try StructureSwiftGen.structure(
                named: typeName,
                forOneOf: schemas,
                cascadingConformances: cascadingConformances,
                rootConformances: rootConformances
            )
            decls = [poly.polyDecl] + poly.dependencies
        default:
            throw Error.rootNotJSONObject
        }
    }

    static func structure(
        named name: String,
        forObject context: DereferencedJSONSchema.ObjectContext,
        cascadingConformances: [String],
        rootConformances: [String]? = nil
    ) throws -> BlockTypeDecl {
        let decls = try context
            .properties
            .sorted { $0.key < $1.key  }
            .map { (key, value) in
                try declsForProp(
                    named: key,
                    for: value,
                    conformances: cascadingConformances
                )
        }.flatMap { $0 }

        return BlockTypeDecl.struct(
            typeName: name,
            conformances: rootConformances ?? cascadingConformances,
            decls
        )
    }

    static func structure(
        named name: String,
        forOneOf schemas: [DereferencedJSONSchema],
        cascadingConformances: [String],
        rootConformances: [String]? = nil
    ) throws -> (polyDecl: Decl, dependencies: [Decl]) {
        let dependencies = try schemas
            .enumerated()
            .map { (idx, schema) -> (String, [Decl]) in
                let name = typeCased("Poly\(name)\(idx)")
                return (
                    name,
                    try declsForType(
                        named: name,
                        for: schema,
                        conformances: cascadingConformances
                    )
                )
            }

        let poly = Typealias(
            alias: .def(.init(name: name)),
            existingType: .def(
                .init(
                    name: "Poly\(dependencies.count)",
                    specializationReps: dependencies.map{ .def(.init(name: $0.0)) },
                    optional: false
                )
            )
        )

        return (polyDecl: poly, dependencies: dependencies.flatMap(\.1))
    }

    static func structure(
        named name: String,
        forArray context: DereferencedJSONSchema.ArrayContext,
        conformances: [String]
    ) throws -> Decl {

        guard let items = context.items,
            case .object(_, let objContext) = items else  {
                return Typealias(alias: .def(.init(name: name)), existingType: .rep(AnyCodable.self))

        }

        return try structure(
            named: name,
            forObject: objContext,
            cascadingConformances: conformances
        )
    }

    /// Create the decls needed to represent the structures in use
    /// by a PolyX.
    static func declsForType(
        named name: String,
        for schema: DereferencedJSONSchema,
        conformances: [String]
    ) throws -> [Decl] {
        let type: SwiftTypeRep
        let structureDecl: Decl?

        do {
            type = try swiftType(from: schema, allowPlaceholders: false)
            structureDecl = nil
        } catch {
            switch schema {
            case .object(let context, let objContext):
                let newTypeName = typeCased(name)

                // TODO: ideally distinguish between these
                //      but that requires generating Swift code
                //      for custom encoding/decoding
                let optional = !context.required || context.nullable

                let typeIntermediate = SwiftTypeRep.def(.init(name: newTypeName))

                type = optional ? typeIntermediate.optional : typeIntermediate

                structureDecl = try structure(
                    named: newTypeName,
                    forObject: objContext,
                    cascadingConformances: conformances
                )

            case .array(let context, let arrayContext):
                let newTypeName = typeCased(name)

                // TODO: ideally distinguish between these
                //      but that requires generating Swift code
                //      for custom encoding/decoding
                let optional = !context.required || context.nullable

                let typeIntermediate = SwiftTypeRep.def(SwiftTypeDef(name: newTypeName).array)

                type = optional ? typeIntermediate.optional : typeIntermediate

                structureDecl = try structure(
                    named: newTypeName,
                    forArray: arrayContext,
                    conformances: conformances
                )
            default:
                throw SwiftTypeError.typeNotFound
            }
        }
        return [
            structureDecl ?? Typealias(
                alias: .def(.init(name: name)),
                existingType: type
            )
        ].compactMap { $0 }
    }

    /// Create the decls needed to represent the substructure of
    /// a property with the given name.
    static func declsForProp(
        named name: String,
        for schema: DereferencedJSONSchema,
        conformances: [String]
    ) throws -> [Decl] {
        let type: SwiftTypeRep
        let structureDecl: Decl?

        do {
            type = try swiftType(from: schema, allowPlaceholders: false)
            structureDecl = nil
        } catch {
            switch schema {
            case .object(let context, let objContext):
                let newTypeName = typeCased(name)

                // TODO: ideally distinguish between these
                //      but that requires generating Swift code
                //      for custom encoding/decoding
                let optional = !context.required || context.nullable

                let typeIntermediate = SwiftTypeRep.def(.init(name: newTypeName))

                type = optional ? typeIntermediate.optional : typeIntermediate

                structureDecl = try structure(
                    named: newTypeName,
                    forObject: objContext,
                    cascadingConformances: conformances
                )

            case .array(let context, let arrayContext):
                let newTypeName = typeCased(name)

                // TODO: ideally distinguish between these
                //      but that requires generating Swift code
                //      for custom encoding/decoding
                let optional = !context.required || context.nullable

                let typeIntermediate = SwiftTypeRep.def(SwiftTypeDef(name: newTypeName).array)

                type = optional ? typeIntermediate.optional : typeIntermediate

                structureDecl = try structure(
                    named: newTypeName,
                    forArray: arrayContext,
                    conformances: conformances
                )
            default:
                throw SwiftTypeError.typeNotFound
            }
        }
        return [
            PropDecl.let(propName: name, swiftType: type, nil),
            structureDecl
            ].compactMap { $0 }
    }

    public enum Error: Swift.Error {
        case rootNotJSONObject
    }
}
