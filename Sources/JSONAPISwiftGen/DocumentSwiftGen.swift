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

    public init(structure: JSONSchema, swiftTypeName: String) throws {
        self.swiftTypeName = swiftTypeName
        self.structure = structure

        decls = try DataDocumentSwiftGen.swiftDecls(from: structure, swiftTypeName: swiftTypeName)
        swiftCode = DataDocumentSwiftGen.swiftCode(from: decls)
    }

    static func swiftCode(from decls: [Decl]) -> String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
    }

    static func swiftDecls(from structure: JSONSchema, swiftTypeName: String) throws -> [Decl] {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        guard let data = resourceObjectContextB.properties["data"] else {
            throw Error.unhandledDocument
        }

        var allDecls = [Decl]()

        let primaryResourceBodyType: SwiftTypeRep
        switch data {
        case .object:
            let resourceObject = try ResourceObjectSwiftGen(structure: data)

            let isNullablePrimaryResource = data.nullable

            // SingleResourceBody<PrimaryResource>
            primaryResourceBodyType = .def(.init(name: "SingleResourceBody",
                                             specializationReps: [
                                                .def(.init(name: resourceObject.swiftTypeName,
                                                           specializationReps: [],
                                                           optional: isNullablePrimaryResource))
                ]))

            allDecls.append(contentsOf: resourceObject.decls)

        case let .array(_, dataArrayContextB):
            guard let dataItem = dataArrayContextB.items,
                case .object = dataItem else {
                    throw Error.expectedDataArrayToDefineItems
            }

            let resourceObject = try ResourceObjectSwiftGen(structure: dataItem)

            primaryResourceBodyType = .def(.init(name: "ManyResourceBody",
                                             specializationReps: [
                                                .def(.init(name: resourceObject.swiftTypeName,
                                                           specializationReps: []))
                ]))

            allDecls.append(contentsOf: resourceObject.decls)

        default:
            throw Error.unhandledDocument
        }

        // TODO: handle includes

        allDecls.append(Typealias(alias: .def(.init(name: swiftTypeName, specializations: [])),
                                  existingType: .def(.init(name: "JSONAPI.Document",
                                                           specializationReps: [
                                                            primaryResourceBodyType,
                                                            .init(NoMetadata.self),
                                                            .init(NoLinks.self),
                                                            .init(NoIncludes.self),
                                                            .init(NoAPIDescription.self),
                                                            .init(UnknownJSONAPIError.self)
                                    ]))))

        return allDecls
    }
}

public extension DataDocumentSwiftGen {
    enum Error: Swift.Error {
        case rootNotJSONObject
        case expectedDataArrayToDefineItems

        case unhandledDocument
    }
}
