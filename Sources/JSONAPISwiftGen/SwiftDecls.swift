
import OpenAPIKit
import JSONAPI

public protocol DefValue: SwiftCodeRepresentable {
    var value: String { get }
}

/// An anonymous function () -> Type such as is used
/// to define computed properties.
///
/// In `var x: { return "value" }`
/// the `DynamicValue` is `{ return "value" }`
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

    public static func placeholder(name: String, type: SwiftTypeRep) -> Value {
        return Value(value: swiftPlaceholder(name: name,
                                             type: type))
    }

    public static func tuple(elements: [(name: String, value: String)]) -> Value {
        return Value(value: "("
            + elements.map { "\($0.name): \($0.value)" }.joined(separator: ", ")
            + ")")
    }

    public static func array(elements: [Value]) -> Value {
        return Value(value: "["
            + elements.map { $0.value }.joined(separator: ", ")
            + "]")
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
        let swiftType: SwiftTypeRep
        let valueString: String

        switch self {
        case .let(propName: let name, swiftType: let typeName, let value):
            propType = "let"
            propName = name
            swiftType = typeName
            valueString = value.map { $0.swiftCode } ?? ""
        case .var(propName: let name, swiftType: let typeName, let value):
            propType = "var"
            propName = name
            swiftType = typeName
            valueString = value.map { $0.swiftCode } ?? ""
        }

        let nameAndTypeString = swiftType.isInferred
            ? propName
            : "\(propName): \(swiftType.swiftCode)"

        return "\(propType) \(nameAndTypeString)" + valueString
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
    case `extension`(typeName: String, conformances: [String]?, conditions: [String]?, [Decl])

    public var swiftCode: String {
        let declType: String
        let typeNameString: String
        let conformancesString: String
        let conditionsString: String
        let contentString: String

        func conformances(from: [String]?) -> String {
            return from.map { ": " + $0.joined(separator: ", ") } ?? ""
        }

        func conditions(from: [String]?) -> String {
            return from.map { " where " + $0.joined(separator: ", ") } ?? ""
        }

        switch self {
        case .enum(let typeName, let conforms, let contents):
            declType = "enum"
            typeNameString = typeName
            contentString = contents.map { $0.swiftCode }.joined(separator:"\n")
            conformancesString = conformances(from: conforms)
            conditionsString = ""
        case .struct(let typeName, let conforms, let contents):
            declType = "struct"
            typeNameString = typeName
            contentString = contents.map { $0.swiftCode }.joined(separator:"\n")
            conformancesString = conformances(from: conforms)
            conditionsString = ""
        case .extension(let typeName, let conforms, let condits, let contents):
            declType = "extension"
            typeNameString = typeName
            contentString = contents.map { $0.swiftCode }.joined(separator:"\n")
            conformancesString = conformances(from: conforms)
            conditionsString = conditions(from: condits)
        }
        return "\(declType) \(typeNameString)\(conformancesString)\(conditionsString) {\n\(contentString)\n}"
    }

    public func appending(_ decl: Decl) -> BlockTypeDecl {
        return appending([decl])
    }

    public func appending(_ newDecls: [Decl]) -> BlockTypeDecl {
        switch self {
        case .enum(typeName: let typeName,
                   conformances: let conformances,
                   let decls):
            return .enum(typeName: typeName,
                         conformances: conformances,
                         decls + newDecls)
        case .struct(typeName: let typeName,
                     conformances: let conformances,
                     let decls):
            return .struct(typeName: typeName,
                           conformances: conformances,
                           decls + newDecls)
        case .extension(typeName: let typeName,
                        conformances: let conformances,
                        conditions: let conditions,
                        let decls):
            return .extension(typeName: typeName,
                              conformances: conformances,
                              conditions: conditions,
                              decls + newDecls)
        }
    }

    public static func enumCase(_ name: String) -> Decl {
        return EnumCase(name: name)
    }

    struct EnumCase: Decl {
        let swiftCode: String

        init(name: String) {
            swiftCode = "case \(name)"
        }
    }
}

public struct Scoping: SwiftCodeRepresentable, Equatable {
    public let `static`: Bool
    public let privacy: Privacy

    public init(static: Bool = false, privacy: Privacy = .internal) {
        self.static = `static`
        self.privacy = privacy
    }

    public static let `default`: Scoping = .init()

    public enum Privacy: String {
        case `public`
        case `private`
        case `fileprivate`
        case `internal`
    }

    public var swiftCode: String {
        let privacyString = privacy == .internal ? "" : " \(privacy.rawValue)"
        return `static` ? "static\(privacyString)" : privacy.rawValue
    }
}

public struct Function: Decl {
    public let scoping: Scoping
    public let name: String
    public let specializations: [SwiftTypeDef]?
    public let arguments: [(name: String, type: SwiftTypeRep)]
    public let conditions: [(type: SwiftTypeDef, conformance: String)]?
    public let body: [Decl]
    public let returnType: SwiftTypeRep?

    public init(scoping: Scoping = .default,
                name: String,
                specializations: [SwiftTypeDef]? = nil,
                arguments: [(name: String, type: SwiftTypeRep)] = [],
                conditions: [(type: SwiftTypeDef, conformance: String)]? = nil,
                body: [Decl],
                returnType: SwiftTypeRep? = nil) {
        self.scoping = scoping
        self.name = name
        self.specializations = specializations
        self.arguments = arguments
        self.conditions = conditions
        self.body = body
        self.returnType = returnType
    }

    public var swiftCode: String {
        let bodyString = body
            .map { $0.swiftCode }
            .joined(separator: "\n")

        let argumentsString = arguments
            .map { "\($0.name): \($0.type.swiftCode)" }
            .joined(separator: ", ")

        let specializationsString = specializations
            .map { "<"
                + $0.map { $0.swiftCode }.joined(separator: ", ")
                + ">" }
            ?? ""

        let conditionsString = conditions
            .map { " where "
                + $0.map { "\($0.type.swiftCode): \($0.conformance)" }.joined(separator: ", ") }
        ?? ""

        let returnString = returnType.map { " -> \($0.swiftCode)" } ?? ""

        let scopingString = scoping == .default ? "" : "\(scoping.swiftCode) "

        return "\(scopingString)func \(name)\(specializationsString)(\(argumentsString))\(conditionsString)\(returnString) {\n\(bodyString)\n}"
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

public struct Import: Decl {
    public let module: String

    public init(module: String) {
        self.module = module
    }

    public var swiftCode: String {
        return "import \(module)"
    }
}
