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
    public let swiftCode: String
    public let swiftTypeName: String

    public init(jsonAPITypeName: String) throws {
        self.swiftTypeName = ResourceObjectStubSwiftGen.typeCased(jsonAPITypeName)

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

        swiftCode = ResourceObjectStubSwiftGen.swiftCode(from: decls)
    }

    static func swiftCode(from decls: [Decl]) -> String {
        return decls.map { $0.swiftCode }.joined(separator: "\n")
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
