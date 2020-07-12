//
//  StructDocumentSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/7/19.
//

import Foundation
import OpenAPIKit
import JSONAPI

/// Creates a request or response document (no difference encoded in this
/// representation) where the document structure is represented by a
/// Codable `struct`.
public struct StructDocumentSwiftGen: DocumentSwiftGenerator {
    /// The OpenAPI structure.
    public let structure: DereferencedJSONSchema
    public let decls: [Decl]
    public let swiftTypeName: String
    public let structGenerator: StructureSwiftGen
    public let exampleGenerator: ExampleSwiftGen?
    public let testExampleFuncs: [TestFunctionGenerator]

    public let swiftCodeDependencies: [SwiftGenerator] = []

    public init(
        swiftTypeName: String,
        structure: DereferencedJSONSchema,
        allowPlaceholders: Bool = true,
        example: ExampleSwiftGen? = nil,
        testExampleFuncs: [TestFunctionGenerator] = []
    ) throws {
        self.swiftTypeName = swiftTypeName
        self.structure = structure
        self.exampleGenerator = example
        self.testExampleFuncs = testExampleFuncs

        let structGenerator = try StructureSwiftGen(
            swiftTypeName: swiftTypeName,
            structure: structure,
            cascadingConformances: ["Codable", "Equatable"]
        )
        self.structGenerator = structGenerator

        self.decls = structGenerator.decls
    }
}
