//
//  XCTestClassSwiftGen.swift
//  JSONAPISwiftGen
//
//  Created by Mathew Polzin on 9/20/19.
//

import Foundation

public struct XCTestClassSwiftGen: SwiftGenerator {
    public let decls: [Decl]

    /// Craete a test class that has functions that just
    /// call the functions given as the final argument of
    /// the initializer.
    ///
    /// Each test function looks like:
    /// ```
    /// <generated_name>() {
    ///     <forwardingFullyQualifiedTestName>()
    /// }
    /// ```
    ///
    public init(className: String,
                importNames: Set<String>,
                forwardingFullyQualifiedTestNames: [String]) {
        let tests: [(name: String, body: [Decl])] = forwardingFullyQualifiedTestNames
            .map { testName in
                let testCallDecl = LiteralSwiftCode("\(testName)()")
                let generatedTestName = testName.replacingOccurrences(of: ".",
                                                                      with: "_")
                return (name: generatedTestName, body: [testCallDecl])
        }
        self.init(className: className,
                  importNames: importNames,
                  tests: tests)
    }

    public init(className: String,
                importNames: Set<String>,
                tests: [(name: String, body: [Decl])]) {

        let imports = (importNames
            .map(Import.init(module:)))
            + [Import.XCTest]

        func testName(_ str: String) -> String {
            return "test_\(propertyCased(str))"
        }

        let testFuncDecls: [Function] = tests.map { (name, body) in
            let funcName = testName(name)
            return Function(name: funcName, body: body)
        }

        let allTestsValueString = "[\n" + tests
            .map { testName($0.name) }
            .map { "(\"\($0)\", \($0))" }
            .joined(separator: ", \n")
            + "\n]"
        let allTestsVar = StaticDecl(PropDecl.var(propName: "allTests",
                                                  swiftType: .def(.init(name: "[(String, (\(className)) -> () -> Void)]")),
                                                  Value(value: allTestsValueString)))

        let classDecl = BlockTypeDecl.class(typeName: className,
                                            parent: "XCTestCase",
                                            conformances: nil,
                                            [allTestsVar] + testFuncDecls)

        decls = imports
            + [classDecl]
    }
}
