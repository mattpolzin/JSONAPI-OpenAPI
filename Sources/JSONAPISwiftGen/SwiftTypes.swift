//
//  SwiftTypes.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 7/26/19.
//

import Foundation
import JSONAPI
import Poly
import AnyCodable

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol SwiftType: SwiftCodeRepresentable {
    static var swiftTypeDef: SwiftTypeDef { get }
}

public extension SwiftType {
    static var swiftCode: String {
        return swiftTypeDef.swiftCode
    }

    var swiftCode: String {
        return Self.swiftCode
    }
}

public struct SwiftTypeDef: SwiftCodeRepresentable {
    public let name: String
    public let specializations: [SwiftTypeRep]
    public let optional: Bool

    public var swiftCode: String {
        let specializationArray = specializations.map { $0.swiftCode }
        let specializationString = specializationArray.count > 0
            ? "<" + specializationArray.joined(separator: ", ") + ">"
            : ""
        let optionalString = optional
            ? "?"
            : ""
        return "\(name)\(specializationString)\(optionalString)"
    }

    public init(name: String, specializationReps: [SwiftTypeRep], optional: Bool = false) {
        self.name = name
        self.specializations = specializationReps
        self.optional = optional
    }

    public init(name: String,
                specializations: [SwiftType.Type] = [],
                optional: Bool = false) {
        self.name = name
        self.specializations = specializations.map(SwiftTypeRep.init)
        self.optional = optional
    }
}

public enum SwiftTypeRep: SwiftCodeRepresentable, ExpressibleByStringLiteral {
    case rep(SwiftType.Type)
    case def(SwiftTypeDef)
    case inferred

    public var isInferred: Bool {
        guard case .inferred = self else {
            return false
        }
        return true
    }

    public var swiftCode: String {
        switch self {
        case .rep(let swiftable):
            return swiftable.swiftCode
        case .def(let swiftable):
            return swiftable.swiftCode
        case .inferred:
            return ""
        }
    }

    /// Get the Type's name. This notably omits any generic parameters.
    public var typeName: String {
        switch self {
        case .rep(let type):
            return type.swiftTypeDef.name
        case .def(let def):
            return def.name
        case .inferred:
            return ""
        }
    }

    public init(_ rep: SwiftType.Type) {
        self = .rep(rep)
    }

    public init(_ def: SwiftTypeDef) {
        self = .def(def)
    }

    public init(_ stringDef: String) {
        self = .def(.init(name: stringDef))
    }

    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }

    public var optional: SwiftTypeRep {
        switch self {
        case .def(let def):
            return .init(SwiftTypeDef(name: def.swiftCode,
                                      specializationReps: [],
                                      optional: true))
        case .rep(let rep):
            return .init(SwiftTypeDef(name: rep.swiftCode,
                                      specializationReps: [],
                                      optional: true))
        case .inferred:
            return self
        }
    }
}

// MARK: - Conformances

extension String: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "String")
    }
}

extension Int: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Int")
    }
}

extension Double: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Double")
    }
}

extension Bool: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Bool")
    }
}

extension URL: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "URL")
    }
}

extension URLRequest: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "URLRequest")
    }
}

extension AnyCodable: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "AnyCodable")
    }
}

extension Data: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Data")
    }
}

extension Optional: SwiftType, SwiftCodeRepresentable where Wrapped: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: Wrapped.swiftCode,
                     optional: true)
    }
}

extension Array: SwiftType, SwiftCodeRepresentable where Element: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "[\(Element.swiftCode)]")
    }
}

// MARK: JSONAPI

extension Attribute: SwiftType, SwiftCodeRepresentable where RawValue: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Attribute",
                     specializations: [RawValue.self])
    }
}

extension TransformedAttribute: SwiftType, SwiftCodeRepresentable where RawValue: SwiftType, Transformer: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "TransformedAttribute",
                     specializations: [RawValue.self, Transformer.self])
    }
}

extension ToOneRelationship: SwiftType, SwiftCodeRepresentable where Identifiable: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "ToOneRelationship",
                     specializations: [Identifiable.self])
    }
}

extension ToManyRelationship: SwiftType, SwiftCodeRepresentable where Relatable: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "ToManyRelationship",
                     specializations: [Relatable.self])
    }
}

extension SingleResourceBody: SwiftType, SwiftCodeRepresentable where Entity: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "SingleResourceBody",
                     specializations: [Entity.self])
    }
}

extension ManyResourceBody: SwiftType, SwiftCodeRepresentable where Entity: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "ManyResourceBody",
                     specializations: [Entity.self])
    }
}

extension NoMetadata: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoMetadata")
    }
}

extension NoLinks: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoLinks")
    }
}

extension NoRelationships: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoRelationships")
    }
}

extension NoAttributes: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoAttributes")
    }
}

extension NoResourceBody: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoResourceBody")
    }
}

extension NoAPIDescription: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoAPIDescription")
    }
}

extension UnknownJSONAPIError: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "UnknownJSONAPIError")
    }
}

extension Unidentified: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Unidentified")
    }
}

extension NoIncludes: SwiftType, SwiftCodeRepresentable {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "NoIncludes")
    }
}

extension Includes: SwiftType, SwiftCodeRepresentable where I: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Includes",
                     specializations: [I.self])
    }
}

extension Include1: SwiftType, SwiftCodeRepresentable where A: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include1",
                     specializations: [A.self])
    }
}

extension Include2: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include2",
                     specializations: [A.self,
                                       B.self])
    }
}

extension Include3: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include3",
                     specializations: [A.self,
                                       B.self,
                                       C.self])
    }
}

extension Include4: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType, D: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include4",
                     specializations: [A.self,
                                       B.self,
                                       C.self,
                                       D.self])
    }
}

extension Include5: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType, D: SwiftType, E: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include5",
                     specializations: [A.self,
                                       B.self,
                                       C.self,
                                       D.self,
                                       E.self])
    }
}

extension Include6: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType, D: SwiftType, E: SwiftType, F: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include6",
                     specializations: [A.self,
                                       B.self,
                                       C.self,
                                       D.self,
                                       E.self,
                                       F.self])
    }
}

extension Include7: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType, D: SwiftType, E: SwiftType, F: SwiftType, G: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include7",
                     specializations: [A.self,
                                       B.self,
                                       C.self,
                                       D.self,
                                       E.self,
                                       F.self,
                                       G.self])
    }
}

extension Include8: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType, D: SwiftType, E: SwiftType, F: SwiftType, G: SwiftType, H: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include8",
                     specializations: [A.self,
                                       B.self,
                                       C.self,
                                       D.self,
                                       E.self,
                                       F.self,
                                       G.self,
                                       H.self])
    }
}

extension Include9: SwiftType, SwiftCodeRepresentable where A: SwiftType, B: SwiftType, C: SwiftType, D: SwiftType, E: SwiftType, F: SwiftType, G: SwiftType, H: SwiftType, I: SwiftType {
    public static var swiftTypeDef: SwiftTypeDef {
        return .init(name: "Include9",
                     specializations: [A.self,
                                       B.self,
                                       C.self,
                                       D.self,
                                       E.self,
                                       F.self,
                                       G.self,
                                       H.self,
                                       I.self])
    }
}
