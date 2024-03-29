//
//  JSONAPIDocumentSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/7/19.
//

import Foundation
import OpenAPIKit30
import JSONAPI

/// Only handles success (Data) case for JSON:API Document.
/// Eventually I would like to expand this to read through multiple OpenAPI responses
/// and build a representation of a JSON:API Document that can handle both
/// Data and Error cases.
public struct JSONAPIDocumentSwiftGen: DocumentSwiftGenerator {
    public let structure: DereferencedJSONSchema
    public let decls: [Decl]
    public let swiftTypeName: String
    public let resourceObjectGenerators: Set<ResourceObjectSwiftGen>
    public let exampleGenerators: [ExampleSwiftGen]
    public let testExampleFuncs: [TestFunctionGenerator]

    public var swiftCodeDependencies: [SwiftGenerator] {
        Array(resourceObjectGenerators)
    }

    public init(
        swiftTypeName: String,
        structure: DereferencedJSONSchema,
        allowPlaceholders: Bool = true,
        examples: [ExampleSwiftGen] = [],
        testExampleFuncs: [TestFunctionGenerator] = []
    ) throws {
        self.swiftTypeName = swiftTypeName
        self.structure = structure
        self.exampleGenerators = examples
        self.testExampleFuncs = testExampleFuncs

        (decls, resourceObjectGenerators) = try JSONAPIDocumentSwiftGen.swiftDecls(
            from: structure,
            swiftTypeName: swiftTypeName,
            allowPlaceholders: allowPlaceholders
        )
    }

    static func swiftDeclsForErrorDocument(
        from resourceObjectContext: DereferencedJSONSchema.ObjectContext,
        swiftTypeName: String
    ) throws -> [Decl] {
        guard let errorsSchema = resourceObjectContext.properties["errors"],
            case .array(_, let arrayContext) = errorsSchema,
            let errorsItems = arrayContext.items else {
                throw Error.unhandledDocument("Expected errors array but did not find one")
        }

        let errorTypeName = swiftTypeName + "_Error"
        let errorPayloadTypeName = errorTypeName + "Payload"

        let errorsItemsDecls: [Decl]
        do { //GenericJSONAPIError<ErrorPayload>
            let errorTypealias = Typealias(
                alias: .def(
                    .init(name: errorTypeName)
                ),
                existingType: .def(
                    .init(
                        name: "GenericJSONAPIError",
                        specializationReps: [.def(.init(name: errorPayloadTypeName))]
                    )
                )
            )

            errorsItemsDecls = try StructureSwiftGen(
                swiftTypeName: errorPayloadTypeName,
                structure: errorsItems,
                cascadingConformances: ["Codable", "Equatable"]
            ).decls
                + [errorTypealias]
        } catch let error {
            throw Error.failedToCreateErrorsStructure(underlyingError: error)
        }

        let documentTypealiasDecl = Typealias(
            alias: .def(.init(name: swiftTypeName)),
            existingType: .def(
                .init(
                    name: "JSONAPI.Document",
                    specializationReps: [
                        .init(NoResourceBody.self),
                        .init(NoMetadata.self),
                        .init(NoLinks.self),
                        .init(NoIncludes.self),
                        .init(NoAPIDescription.self),
                        .def(.init(name: errorTypeName))
                    ]
                )
            )
        )

        return errorsItemsDecls + [documentTypealiasDecl]
    }

    static func swiftDecls(
        from structure: DereferencedJSONSchema,
        swiftTypeName: String,
        allowPlaceholders: Bool
    ) throws -> ([Decl], Set<ResourceObjectSwiftGen>) {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        let rootProperties = resourceObjectContextB.properties

        guard let data = rootProperties["data"] else {
            if rootProperties["errors"] != nil {
                return (
                    try swiftDeclsForErrorDocument(
                        from: resourceObjectContextB,
                        swiftTypeName: swiftTypeName
                    ),
                    Set()
                )
            }

            let rootPropertyKeys = rootProperties.keys
            let rootPropertyKeysString = rootPropertyKeys.count > 0
                ? rootPropertyKeys.map { "'\($0)'" }.joined(separator: ", ")
                : "no keys"
            throw Error.unhandledDocument("Only handles data and error documents. Root keys found (\(rootPropertyKeysString)) did not match 'errors' or 'data'")
        }

        var allDecls = [Decl]()
        var allResourceObjectGenerators = Set<ResourceObjectSwiftGen>()

        let primaryResourceBodyType: SwiftTypeRep
        let primaryResourceTypeName: String
        switch data {
        case .object:
            let resourceObject = try ResourceObjectSwiftGen(
                structure: data,
                allowPlaceholders: allowPlaceholders
            )
            primaryResourceTypeName = resourceObject.resourceTypeName

            let isNullablePrimaryResource = data.nullable

            // SingleResourceBody<PrimaryResource>
            primaryResourceBodyType = .def(
                .init(
                    name: "SingleResourceBody",
                    specializationReps: [
                        .def(
                            .init(
                                name: primaryResourceTypeName,
                                specializationReps: [],
                                optional: isNullablePrimaryResource
                            )
                        )
                    ]
                )
            )

            allResourceObjectGenerators.insert(resourceObject)

        case let .array(_, dataArrayContextB):
            guard let dataItem = dataArrayContextB.items,
                case .object = dataItem else {
                    throw Error.expectedDataArrayToDefineItems
            }

            let resourceObject = try ResourceObjectSwiftGen(
                structure: dataItem,
                allowPlaceholders: allowPlaceholders
            )
            primaryResourceTypeName = resourceObject.resourceTypeName

            primaryResourceBodyType = .def(
                .init(
                    name: "ManyResourceBody",
                    specializationReps: [
                        .def(
                            .init(
                                name: primaryResourceTypeName,
                                specializationReps: []
                            )
                        )
                    ]
                )
            )

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
            case .one(of: let resourceTypeSchemas, _):
                resources = try Array(Set(resourceTypeSchemas.map {
                    try ResourceObjectSwiftGen(
                        structure: $0,
                        allowPlaceholders: allowPlaceholders
                    )
                })).sorted { $0.resourceTypeName < $1.resourceTypeName }
            default:
                resources = [
                    try ResourceObjectSwiftGen(
                        structure: items,
                        allowPlaceholders: allowPlaceholders
                    )
                ]
            }

            let resourceTypes = resources.map { SwiftTypeRep.def(.init(name: $0.resourceTypeName)) }

            includeType = .def(
                .init(
                    name: "Include\(resourceTypes.count)",
                    specializationReps: resourceTypes
                )
            )


            allResourceObjectGenerators = allResourceObjectGenerators.union(resources)
        } else {
            includeType = .rep(NoIncludes.self)
        }

        allDecls.append(
            Typealias(
                alias: .def(.init(name: swiftTypeName)),
                existingType: .def(
                    .init(
                        name: "JSONAPI.Document",
                        specializationReps: [
                            primaryResourceBodyType,
                            .init(NoMetadata.self),
                            .init(NoLinks.self),
                            includeType,
                            .init(NoAPIDescription.self),
                            "BasicJSONAPIError<AnyCodable>"
                        ]
                    )
                )
            )
        )

        return (allDecls, allResourceObjectGenerators)
    }
}

public extension JSONAPIDocumentSwiftGen {
    enum Error: Swift.Error, CustomDebugStringConvertible {
        case rootNotJSONObject
        case expectedDataArrayToDefineItems
        case expectedIncludedToBeArray
        case expectedIncludedArrayToDefineItems

        case unhandledDocument(String)

        case failedToCreateErrorsStructure(underlyingError: Swift.Error)

        public var debugDescription: String {
            switch self {
            case .rootNotJSONObject:
                return "Tried to parse a JSON:API Document schema that did not have a JSON Schema 'object' type at its root."
            case .expectedDataArrayToDefineItems:
                return "Tried to parse a JSON:API Document schema that appears to represent a collection of resources but no 'items' property defined the primary resource."
            case .expectedIncludedToBeArray:
                return "Tried to parse the Included schema for a JSON:API Document but did not find an array definition."
            case .expectedIncludedArrayToDefineItems:
                return "Tried to parse the Included schema for a JSON:API Document but the 'items' property of the array definition was not found."
            case .unhandledDocument(let description):
                return "Could not parse JSON:API Document: \(description)"

            case .failedToCreateErrorsStructure(underlyingError: let underlyingError):
                return "Tried to parse error JSON:API Document but failed to generate structure to parse errors schema. Underlying error: \(String(describing: underlyingError))"
            }
        }
    }
}
