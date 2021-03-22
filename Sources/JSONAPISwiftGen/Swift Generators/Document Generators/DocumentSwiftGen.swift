//
//  DocumentSwiftGen.swift
//  
//
//  Created by Mathew Polzin on 7/11/20.
//

public protocol DocumentSwiftGenerator: JSONSchemaSwiftGenerator {
    var swiftTypeName: String { get }
    var exampleGenerators: [ExampleSwiftGen] { get }
    var testExampleFuncs: [TestFunctionGenerator] { get }

    var swiftCodeDependencies: [SwiftGenerator] { get }
}

extension DocumentSwiftGenerator {
    /// Generate Swift code not just for this Document's declaration but
    /// also for all declarations required for this Document to compile.
    public var swiftCodeWithDependencies: String {
        return (swiftCodeDependencies
                    .map { $0.swiftCode }
                    + [swiftCode])
            .joined(separator: "\n")
    }
}
