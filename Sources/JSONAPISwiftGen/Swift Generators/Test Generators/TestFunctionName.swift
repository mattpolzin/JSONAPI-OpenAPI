//
//  TestFunctionName.swift
//  
//
//  Created by Mathew Polzin on 4/26/20.
//

import Foundation
import OpenAPIKit

/// A type that holds all information necessary to
/// determine
/// 1. The fully qualified test name (`A.b.test_function()`)
/// 2. The route and endpoint being tested
/// 3. The generated name of the test function that will wrap the
///     fully qualified test name (`test_a_b_test_function()`)
///
/// The reason there is a distinction between **(1)** and **(3)** above
/// is that the actual test functions will be nested within the context of the
/// generated structures representative of OpenAPI/JSON:API components
/// and resources. The functions executed by XCTest will be thin wrappers that
/// call the fully qualified names thus flattening everything so all test functions
/// live side by side in one test class but then in turn call out to the nested test
/// functions by their fully qualified names.
///
/// The class generated by `XCTestClassFileSwiftGen` can be inspected to
/// see this flattening and thin wrapper strategy at work.
///
/// The `rawValue` of a test name is the generated wrapper function
/// name mentioned as bullet **(3)** above.
///
/// Conversely, the name printed in
/// XCTest output can be fed to `init?(rawValue:)` to rebuild
/// the rest of the context for the test function name.
public struct TestFunctionName: Equatable, RawRepresentable {

    public let path: OpenAPI.Path
    public let endpoint: OpenAPI.HttpMethod
    public let direction: HttpDirection
    public let context: TestFunctionLocalContext

    public var testName: String { context.functionName }

    /// The status code being tested, if that information is relevant to the test
    /// context.
    public var testStatusCode: OpenAPI.Response.StatusCode? { context.statusCode }

    /// The raw value is the generated wrapper test function name
    /// for the given test.
    ///
    /// To get the fully qualified name of the test, use `fullyQualifiedTestFunctionName`
    public var rawValue: String {
        return Self.testPrefix +
            nameApplying(pathComponentTransform: Self.functionEncodedName)
                .replacingOccurrences(of: ".", with: "\(Self.periodReplacementCharacter)")
    }

    /// The fully qualified test function name is the name of the test
    /// function nested within a particular context. This is the actual
    /// callable whereas the `rawValue` is the name of the test function
    /// that will call this callable.
    public var fullyQualifiedTestFunctionName: String {
        return nameApplying(pathComponentTransform: Self.swiftName)
    }

    /// This function facilitates a split between the `rawValue` and `fullyQualifiedTestFunctionName`
    /// because the former retains all path information with its `pathComponentTransform` whereas the
    /// latter is lossy with respect to some path component transformations.
    internal func nameApplying(pathComponentTransform: (String) -> String) -> String {
        let components = path.components
            + [endpoint.rawValue, direction.rawValue.capitalized]

        return components
            .map(pathComponentTransform)
            .joined(separator: ".")
            + ".\(testName)"
    }

    public init?(rawValue: String) {
        guard let rangeOfPrefix = rawValue.range(of: Self.testPrefix), rangeOfPrefix.lowerBound == rawValue.startIndex else {
            return nil
        }

        let value = rawValue[rangeOfPrefix.upperBound...]

        var components = value.split(separator: Self.periodReplacementCharacter)

        guard components.count > 2 else {
            return nil
        }

        guard let localContext = TestFunctionLocalContext(
            functionName: Self.functionDecodedName(
                from: String(components.removeLast())
            )
        ) else { return nil }
        self.context = localContext

        guard let direction = HttpDirection(rawValue: String(components.removeLast()).lowercased()) else {
            return nil
        }

        self.direction = direction

        guard let endpoint = OpenAPI.HttpMethod(rawValue: String(components.removeLast())) else {
            return nil
        }

        self.endpoint = endpoint

        self.path = OpenAPI.Path(components.map(String.init).map(Self.functionDecodedName))
    }

    public init(
        path: OpenAPI.Path,
        endpoint: OpenAPI.HttpMethod,
        direction: HttpDirection,
        context: TestFunctionLocalContext
    ) {
        self.path = path
        self.endpoint = endpoint
        self.direction = direction
        self.context = context
    }

    /// For function name encoding we hold onto information like where there are
    /// spaces or braces.
    internal static func functionEncodedName(from string: String) -> String {
        return string
            .replacingOccurrences(of: "{", with: "\(Self.openBraceReplacementCharacter)")
            .replacingOccurrences(of: "}", with: "\(Self.closeBraceReplacementCharacter)")
            .replacingOccurrences(of: " ", with: "\(Self.spaceReplacementCharacter)")
    }

    internal static func functionDecodedName(from string: String) -> String {
        return string
            .replacingOccurrences(of: "\(Self.openBraceReplacementCharacter)", with: "{")
            .replacingOccurrences(of: "\(Self.closeBraceReplacementCharacter)", with: "}")
            .replacingOccurrences(of: "\(Self.spaceReplacementCharacter)", with: " ")
    }

    /// For swift names, we remove braces, escape reserved words, and convert spaces to underscores.
    public static func swiftName(from string: String) -> String {
        let name = string
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: " ", with: "_")
        return Self.escapedKeyword(name)
    }

    internal static func escapedKeyword(_ string: String) -> String {
        if string == "do" { return "`do`" }
        if string == "try" { return "`try`" }
        if string == "continue" { return "`continue`" }
        return string
    }

    public static var testPrefix = "test__"
    private static var openBraceReplacementCharacter: Character = "➊"
    private static var closeBraceReplacementCharacter: Character = "➋"
    private static var spaceReplacementCharacter: Character = "➌"
    private static var periodReplacementCharacter: Character = "➍"
    // ➎ taken by `TestFunctionLocalContext.prefixSeparatorCharacter`.
}

public struct TestFunctionLocalContext: Equatable {
    /// A prefix for all function names in a similar context.
    ///
    /// For example, you may want all request functions to
    /// have one prefix and all response functions to have
    /// a different prefix.
    ///
    /// - Important: The prefix should be a valid function
    ///     name in and of itself (no characters that aren't allowed).
    public let contextPrefix: String

    /// Some meaningful way to describe the context.
    ///
    /// Called a slug because it is not a full-sentence description
    /// or even a summary but rather some (locally) unique string
    /// describing the context.
    ///
    /// - Important: The slug should be a valid function
    ///     name in and of itself (no characters that aren't allowed).
    public let slug: String?

    /// The status code is relevant to the context of a response but
    /// not the context of a request so it is optional.
    ///
    /// - Important: It is not intended that the inavailability of a
    ///     status code be interpreted as an indication that the
    ///     context is that of a request.
    public let statusCode: OpenAPI.Response.StatusCode?

    public init?(functionName: String) {
        guard functionName.first == "_" else { return nil }
        let functionName = functionName.dropFirst()

        let primaryComponents = functionName.components(separatedBy: "__")
        if primaryComponents.count > 1 {
            guard primaryComponents.count == 2 else { return nil }
            guard let code = OpenAPI.Response.StatusCode(rawValue: primaryComponents[1]) else { return nil }
            statusCode = code
        } else {
            statusCode = nil
        }

        let prefixAndSlug = primaryComponents[0]

        let prefix = prefixAndSlug.prefix(while: { $0 != Self.prefixSeparatorCharacter })
        if prefix.count > 0 {
            contextPrefix = String(prefix)
        } else {
            contextPrefix = ""
        }

        let slug = prefixAndSlug[prefixAndSlug.index(after: prefix.endIndex)...]
        if slug.count > 0 {
            self.slug = String(slug)
        } else {
            self.slug = nil
        }
    }

    public init(
        contextPrefix: String = "",
        slug: String?,
        statusCode: OpenAPI.Response.StatusCode?
    ) {
        self.contextPrefix = contextPrefix
        self.slug = slug
        self.statusCode = statusCode
    }

    public var functionName: String {
        let statusCodeNameSuffix = statusCode.map { "__\($0.rawValue)" } ?? ""

        let name = contextPrefix
            + "\(Self.prefixSeparatorCharacter)"
            + (slug ?? "")

        return "_\(name)\(statusCodeNameSuffix)"
    }

    // ➊ through ➍ taken by `TestFunctionName`.
    private static var prefixSeparatorCharacter: Character = "➎"
}
