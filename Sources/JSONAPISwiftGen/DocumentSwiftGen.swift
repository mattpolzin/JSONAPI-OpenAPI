//
//  DocumentSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/7/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

/// Only handles success (Data) case for JSON:API Document.
/// Eventually I would like to expand this to read through multiple OpenAPI responses
/// and build a representation of a JSON:API Document that can handle both
/// Data and Error cases.
public struct DataDocumentSwiftGen: JSONSchemaSwiftGenerator {
    public let structure: JSONSchema
    public let decls: [Decl]
    public let swiftCode: String
    public let swiftTypeName: String
    public let resourceObjectGenerators: Set<ResourceObjectSwiftGen>

    /// Generate Swift code not just for this Document's declaration but
    /// also for all declarations required for this Document to compile.
    public var swiftCodeWithDependencies: String {
        return (resourceObjectGenerators
            .map { $0.swiftCode }
            + [swiftCode])
            .joined(separator: "\n")
    }

    public init(structure: JSONSchema, swiftTypeName: String) throws {
        self.swiftTypeName = swiftTypeName
        self.structure = structure

        (decls, resourceObjectGenerators) = try DataDocumentSwiftGen.swiftDecls(from: structure, swiftTypeName: swiftTypeName)
        swiftCode = DataDocumentSwiftGen.swiftCode(from: decls)
    }

    static func swiftCode(from decls: [Decl]) -> String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
    }

    static func swiftDecls(from structure: JSONSchema, swiftTypeName: String) throws -> ([Decl], Set<ResourceObjectSwiftGen>) {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        guard let data = resourceObjectContextB.properties["data"] else {
            throw Error.unhandledDocument("Only handles data documents")
        }

        var allDecls = [Decl]()
        var allResourceObjectGenerators = Set<ResourceObjectSwiftGen>()

        let primaryResourceBodyType: SwiftTypeRep
        let primaryResourceTypeName: String
        switch data {
        case .object:
            let resourceObject = try ResourceObjectSwiftGen(structure: data)
            primaryResourceTypeName = resourceObject.swiftTypeName

            let isNullablePrimaryResource = data.nullable

            // SingleResourceBody<PrimaryResource>
            primaryResourceBodyType = .def(.init(name: "SingleResourceBody",
                                             specializationReps: [
                                                .def(.init(name: primaryResourceTypeName,
                                                           specializationReps: [],
                                                           optional: isNullablePrimaryResource))
                ]))

            allResourceObjectGenerators.insert(resourceObject)

        case let .array(_, dataArrayContextB):
            guard let dataItem = dataArrayContextB.items,
                case .object = dataItem else {
                    throw Error.expectedDataArrayToDefineItems
            }

            let resourceObject = try ResourceObjectSwiftGen(structure: dataItem)
            primaryResourceTypeName = resourceObject.swiftTypeName

            primaryResourceBodyType = .def(.init(name: "ManyResourceBody",
                                             specializationReps: [
                                                .def(.init(name: primaryResourceTypeName,
                                                           specializationReps: []))
                ]))

            allResourceObjectGenerators.insert(resourceObject)

        default:
            throw Error.unhandledDocument("Only handles array or object at root of document")
        }

        let includeType: SwiftTypeRep
        if let includes = resourceObjectContextB.properties["included"] {
            guard case let .array(_, includesArrayContextB) = includes else {
                throw Error.expectedIncludedToBeArray
            }

            guard let items = includesArrayContextB.items else {
                throw Error.expectedIncludedArrayToDefineItems
            }

            // items might be the one and only resource type, or it might be
            // a `oneOf` with resource types within it.
            let resources: [ResourceObjectSwiftGen]
            switch items {
            case .one(of: let resourceTypeSchemas):
                resources = try Array(Set(resourceTypeSchemas.map {
                    try ResourceObjectSwiftGen(structure: $0)
                })).sorted { $0.swiftTypeName < $1.swiftTypeName }
            default:
                resources = [try ResourceObjectSwiftGen(structure: items)]
            }

            let resourceTypes = resources.map { SwiftTypeRep.def(.init(name: $0.swiftTypeName, specializations: [])) }

            includeType = .def(.init(name: "Include\(resourceTypes.count)",
                                      specializationReps: resourceTypes))


            allResourceObjectGenerators = allResourceObjectGenerators.union(resources)
        } else {
            includeType = .rep(NoIncludes.self)
        }

        allDecls.append(Typealias(alias: .def(.init(name: swiftTypeName, specializations: [])),
                                  existingType: .def(.init(name: "JSONAPI.Document",
                                                           specializationReps: [
                                                            primaryResourceBodyType,
                                                            .init(NoMetadata.self),
                                                            .init(NoLinks.self),
                                                            includeType,
                                                            .init(NoAPIDescription.self),
                                                            .init(UnknownJSONAPIError.self)
                                    ]))))

        return (allDecls, allResourceObjectGenerators)
    }
}

public extension DataDocumentSwiftGen {
    enum Error: Swift.Error {
        case rootNotJSONObject
        case expectedDataArrayToDefineItems
        case expectedIncludedToBeArray
        case expectedIncludedArrayToDefineItems

        case unhandledDocument(String)
    }
}
