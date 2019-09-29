//
//  ResourceObjectStubSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/8/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

public struct ResourceObjectStubSwiftGen: ResourceTypeSwiftGenerator {
    public let decls: [Decl]
    public let resourceTypeName: String
    public let exportedSwiftTypeNames: Set<String>

    public init(jsonAPITypeName: String) throws {
        self.resourceTypeName = typeCased(jsonAPITypeName)
        self.exportedSwiftTypeNames = Set([resourceTypeName])

        let descriptionTypeName = "\(resourceTypeName)Description"

        let descriptionBlock = BlockTypeDecl.enum(typeName: descriptionTypeName,
                                                  conformances: ["JSONAPI.ResourceObjectDescription"],
                                                  [
                                                    StaticDecl(.let(propName: "jsonType", swiftType: .init(String.self), .init(value: "\"\(jsonAPITypeName)\""))),
                                                    Typealias(alias: "Attributes", existingType: .init(NoAttributes.self)),
                                                    Typealias(alias: "Relationships", existingType: .init(NoRelationships.self))
        ])

        let alias = Typealias(alias: .init(resourceTypeName),
                              existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                               specializationReps: [
                                                                .init(descriptionTypeName),
                                                                .init(NoMetadata.self),
                                                                .init(NoLinks.self),
                                                                .init(String.self)
                              ])))


        decls = [
            descriptionBlock,
            alias
        ]
    }
}

private extension ResourceObjectStubSwiftGen {
    enum Key: String {
        case type
        case id
        case attributes
        case relationships
        case data
    }
}

extension ResourceObjectStubSwiftGen: Hashable {
    public static func == (lhs: ResourceObjectStubSwiftGen, rhs: ResourceObjectStubSwiftGen) -> Bool {
        return lhs.resourceTypeName == rhs.resourceTypeName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(resourceTypeName)
    }
}
