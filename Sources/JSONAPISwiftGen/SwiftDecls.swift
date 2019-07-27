
import OpenAPIKit
import JSONAPI

public protocol DefValue: SwiftCodeRepresentable {
    var value: String { get }
}

public struct DynamicValue: DefValue {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public var swiftCode: String {
        return "{ return \(value) }"
    }
}

extension DynamicValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: String) {
        value = stringLiteral
    }
}

public struct Value: DefValue {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public var swiftCode: String {
        return " = \(value)"
    }
}

extension Value: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public init(stringLiteral: String) {
        self.init(value: stringLiteral)
    }
}

public protocol Decl: SwiftCodeRepresentable {}

public enum PropDecl: Decl {
    case `let`(propName: String, swiftType: SwiftTypeRep, Value?)
    case `var`(propName: String, swiftType: SwiftTypeRep, DefValue?)

    public var swiftCode: String {
        let propType: String
        let propName: String
        let swiftTypeString: String
        let valueString: String

        switch self {
        case .let(propName: let name, swiftType: let typeName, let value):
            propType = "let"
            propName = name
            swiftTypeString = typeName.swiftCode
            valueString = value.map { $0.swiftCode } ?? ""
        case .var(propName: let name, swiftType: let typeName, let value):
            propType = "var"
            propName = name
            swiftTypeString = typeName.swiftCode
            valueString = value.map { $0.swiftCode } ?? ""
        }

        return "\(propType) \(propName): \(swiftTypeString)" + valueString
    }
}

public struct StaticDecl: Decl {
    public let decl: PropDecl

    public init(_ decl: PropDecl) {
        self.decl = decl
    }

    public var swiftCode: String {
        return "static \(decl.swiftCode)"
    }
}

public enum BlockTypeDecl: Decl {
    case `enum`(typeName: String, conformances: [String]?, [Decl])
    case `struct`(typeName: String, conformances: [String]?, [Decl])

    public var swiftCode: String {
        let declType: String
        let typeNameString: String
        let conformancesString: String
        let contentString: String

        func conformances(from: [String]?) -> String {
            return from.map { ": " + $0.joined(separator: ", ") } ?? ""
        }

        switch self {
        case .enum(let typeName, let conforms, let contents):
            declType = "enum"
            typeNameString = typeName
            contentString = contents.map { $0.swiftCode }.joined(separator:"\n")
            conformancesString = conformances(from: conforms)
        case .struct(let typeName, let conforms, let contents):
            declType = "struct"
            typeNameString = typeName
            contentString = contents.map { $0.swiftCode }.joined(separator:"\n")
            conformancesString = conformances(from: conforms)
        }
        return "\(declType) \(typeNameString)\(conformancesString) {\n\(contentString)\n}"
    }
}

public struct Typealias: Decl {
    public let alias: SwiftTypeRep
    public let existingType: SwiftTypeRep

    public init(alias: SwiftTypeRep, existingType: SwiftTypeRep) {
        self.alias = alias
        self.existingType = existingType
    }

    public var swiftCode: String {
        return "typealias \(alias.swiftCode) = \(existingType.swiftCode)"
    }
}
