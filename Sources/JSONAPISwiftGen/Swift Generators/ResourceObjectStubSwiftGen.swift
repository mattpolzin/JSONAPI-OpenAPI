//
//  ResourceObjectStubSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/8/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

public struct ResourceObjectStubSwiftGen: TypedSwiftGenerator {
    public let decls: [Decl]
    public let swiftTypeName: String

    public init(jsonAPITypeName: String) throws {
        self.swiftTypeName = typeCased(jsonAPITypeName)

        let descriptionTypeName = "\(swiftTypeName)Description"
        decls = [
            BlockTypeDecl.enum(typeName: descriptionTypeName,
                conformances: ["JSONAPI.ResourceObjectDescription"],
                [
                    StaticDecl(.let(propName: "jsonType", swiftType: .init(String.self), .init(value: "\"\(jsonAPITypeName)\""))),
                    Typealias(alias: "Attributes", existingType: .init(NoAttributes.self)),
                    Typealias(alias: "Relationships", existingType: .init(NoRelationships.self))
            ]),
            Typealias(alias: .init(swiftTypeName),
                      existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                       specializationReps: [
                                                        .init(descriptionTypeName),
                                                        .init(NoMetadata.self),
                                                        .init(NoLinks.self),
                                                        .init(String.self)
                      ])))
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
        return lhs.swiftTypeName == rhs.swiftTypeName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(swiftTypeName)
    }
}
