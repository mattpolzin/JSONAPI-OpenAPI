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
/// - Important: You must also expose the `defaultErrorDecl`
///     and `basicErrorDecl` included as a static var on this type
///     somewhere it is accessible. They are used for creating error response
///     documents.
public struct DataDocumentSwiftGen: JSONSchemaSwiftGenerator {
    public let structure: JSONSchema
    public let decls: [Decl]
    public let swiftTypeName: String
    public let resourceObjectGenerators: Set<ResourceObjectSwiftGen>
    public let exampleGenerator: ExampleSwiftGen?
    public let testExampleFunc: OpenAPIExampleTestSwiftGen?

    /// Generate Swift code not just for this Document's declaration but
    /// also for all declarations required for this Document to compile.
    public var swiftCodeWithDependencies: String {
        return (resourceObjectGenerators
            .map { $0.swiftCode }
            + [swiftCode])
            .joined(separator: "\n")
    }

    public static var defaultErrorDecl: Decl { makeDefaultErrorType }
    public static var basicErrorDecl: Decl { makeBasicErrorType }

    public init(swiftTypeName: String,
                structure: JSONSchema,
                allowPlaceholders: Bool = true,
                example: ExampleSwiftGen? = nil,
                testExampleFunc: OpenAPIExampleTestSwiftGen? = nil) throws {
        self.swiftTypeName = swiftTypeName
        self.structure = structure
        self.exampleGenerator = example
        self.testExampleFunc = testExampleFunc

        (decls, resourceObjectGenerators) = try DataDocumentSwiftGen.swiftDecls(from: structure,
                                                                                swiftTypeName: swiftTypeName,
                                                                                allowPlaceholders: allowPlaceholders)
    }

    static func swiftDeclsForErrorDocument(from resourceObjectContext: JSONSchema.ObjectContext,
                                           swiftTypeName: String) throws -> [Decl] {
        guard let errorsSchema = resourceObjectContext.properties["errors"],
            case .array(_, let arrayContext) = errorsSchema,
            let errorsItems = arrayContext.items else {
                throw Error.unhandledDocument("Expected errors array but did not find one")
        }

        let errorTypeName = swiftTypeName + "_Error"
        let errorPayloadTypeName = errorTypeName + "Payload"

        let errorsItemsDecls: [Decl]
        do { //DefaultTestError<ErrorPayload>
            let errorTypealias = Typealias(alias: .def(.init(name: errorTypeName)),
                                           existingType: .def(.init(name: "DefaultTestError",
                                                                    specializationReps: [.def(.init(name: errorPayloadTypeName))])))

            errorsItemsDecls = try StructureSwiftGen(swiftTypeName: errorPayloadTypeName,
                                                     structure: errorsItems,
                                                     cascadingConformances: ["Codable", "Equatable"]).decls
                + [errorTypealias]
        } catch let error {
            throw Error.failedToCreateErrorsStructure(underlyingError: error)
        }

        let documentTypealiasDecl = Typealias(alias: .def(.init(name: swiftTypeName)),
                                              existingType: .def(.init(name: "JSONAPI.Document",
                                                                       specializationReps: [
                                                                        .init(NoResourceBody.self),
                                                                        .init(NoMetadata.self),
                                                                        .init(NoLinks.self),
                                                                        .init(NoIncludes.self),
                                                                        .init(NoAPIDescription.self),
                                                                        .def(.init(name: errorTypeName))
                                              ])))

        return errorsItemsDecls + [documentTypealiasDecl]
    }

    static func swiftDecls(from structure: JSONSchema,
                           swiftTypeName: String,
                           allowPlaceholders: Bool) throws -> ([Decl], Set<ResourceObjectSwiftGen>) {
        guard case let .object(_, resourceObjectContextB) = structure else {
            throw Error.rootNotJSONObject
        }

        let rootProperties = resourceObjectContextB.properties

        guard let data = rootProperties["data"] else {
            if rootProperties["errors"] != nil {
                return (
                    try swiftDeclsForErrorDocument(from: resourceObjectContextB, swiftTypeName: swiftTypeName),
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
            let resourceObject = try ResourceObjectSwiftGen(structure: data,
                                                            allowPlaceholders: allowPlaceholders)
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

            let resourceObject = try ResourceObjectSwiftGen(structure: dataItem,
                                                            allowPlaceholders: allowPlaceholders)
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
                    try ResourceObjectSwiftGen(structure: $0,
                                               allowPlaceholders: allowPlaceholders)
                })).sorted { $0.swiftTypeName < $1.swiftTypeName }
            default:
                resources = [try ResourceObjectSwiftGen(structure: items,
                                                        allowPlaceholders: allowPlaceholders)]
            }

            let resourceTypes = resources.map { SwiftTypeRep.def(.init(name: $0.swiftTypeName)) }

            includeType = .def(.init(name: "Include\(resourceTypes.count)",
                                      specializationReps: resourceTypes))


            allResourceObjectGenerators = allResourceObjectGenerators.union(resources)
        } else {
            includeType = .rep(NoIncludes.self)
        }

        allDecls.append(Typealias(alias: .def(.init(name: swiftTypeName)),
                                  existingType: .def(.init(name: "JSONAPI.Document",
                                                           specializationReps: [
                                                            primaryResourceBodyType,
                                                            .init(NoMetadata.self),
                                                            .init(NoLinks.self),
                                                            includeType,
                                                            .init(NoAPIDescription.self),
                                                            "BasicError"
                                    ]))))

        return (allDecls, allResourceObjectGenerators)
    }
}

public extension DataDocumentSwiftGen {
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

private var makeDefaultErrorType = """
public enum DefaultTestError<ErrorPayload>: JSONAPIError where ErrorPayload: Codable, ErrorPayload: Equatable {
    case unknownError
    case error(ErrorPayload)

    public static var unknown: DefaultTestError { return .unknownError }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .unknownError:
            try container.encode("unknown")
        case .error(let payload):
            try container.encode(payload)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        do {
            self = .error(try container.decode(ErrorPayload.self))
        } catch {
            self = .unknownError
        }
    }
}
""" as LiteralSwiftCode

private var makeBasicErrorType = """
public struct BasicError: JSONAPIError, CustomDebugStringConvertible {
    private let errorDict: [ErrorKey: String]

    public enum ErrorKey: String, CodingKey, CaseIterable {
        case id
        case status
        case code
        case title
        case detail
        case parameter
    }

    private init() { errorDict = [:] }

    public static var unknown: BasicError { return .init() }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ErrorKey.self)

        var dict = [ErrorKey: String]()

        for key in ErrorKey.allCases {
            dict[key] = try container.decodeIfPresent(String.self, forKey: key)
        }

        errorDict = dict
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ErrorKey.self)

        for (key, value) in errorDict {
            try container.encode(value, forKey: key)
        }
    }

    public subscript(_ key: ErrorKey) -> String? {
        return errorDict[key]
    }

    public var debugDescription: String {
        return ErrorKey
            .allCases
            .compactMap { key in errorDict[key].map { "\\(key.rawValue): \\($0)" } }
            .joined(separator: ", ")
    }
}
""" as LiteralSwiftCode
