//
//  File.swift
//  
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import OpenAPIKit
import JSONAPISwiftGen

typealias HttpVerb = OpenAPI.HttpVerb

func produceAPITestPackage(for pathItems: OpenAPI.PathItem.Map,
                           originatingAt server: OpenAPI.Server,
                           outputTo outPath: String) {

    let testDir = outPath + "/Tests/GeneratedAPITests"
    let resourceObjDir = testDir + "/resourceObjects"

    // generate namespaces first
    let contents = try! namespaceDecls(for: pathItems)
        .map { try $0.enumDecl.formattedSwiftCode() }
        .joined(separator: "\n\n")
    write(contents: contents,
          toFileAt: testDir + "/",
          named: "Namespaces.swift")

    // write test helper to file
    let testHelperContents = try! [
        Import(module: "Foundation") as Decl,
        Import(module: "JSONAPI") as Decl,
        Import(module: "AnyCodable") as Decl,
        Import(module: "XCTest") as Decl,
        APIRequestTestSwiftGen.testFuncDecl
        ].map { try $0.formattedSwiftCode() }
        .joined(separator: "")
    write(contents: testHelperContents,
          toFileAt: testDir + "/",
          named: "TestHelpers.swift")

    write(contents: packageFile,
          toFileAt: outPath + "/",
          named: "Package.swift")

    write(contents: linuxMainFile,
          toFileAt: outPath + "/Tests/",
          named: "LinuxMain.swift")

    let results: [(
        httpVerb: HttpVerb,
        path: OpenAPI.PathComponents,
        pathItem: OpenAPI.PathItem,
        documentFileNameString: String,
        apiRequestTest: APIRequestTestSwiftGen?,
        requestDocument: DataDocumentSwiftGen?,
        responseDocuments: [OpenAPI.Response.StatusCode : DataDocumentSwiftGen],
        fullyQualifiedTestFuncNames: [String]
    )]
    results = HttpVerb.allCases.flatMap { httpVerb in
        return pathItems.compactMap { (path, pathItem) in
            guard case let .operations(operations) = pathItem else {
                return nil
            }

            guard let operation = operations.for(httpVerb) else {
                return nil
            }

            let documentFileNameString = documentTypeName(path: path, verb: httpVerb)

            let parameters = operation.parameters

            let apiRequestTest = try? APIRequestTestSwiftGen(server: server,
                                                         pathComponents: path,
                                                         parameters: parameters.compactMap { $0.a })

            let responses = operation.responses
            let responseDocuments = documents(from: responses,
                                              for: httpVerb,
                                              at: path,
                                              on: server,
                                              given: parameters.compactMap { $0.a })

            let requestDocument: DataDocumentSwiftGen?
            do {
                try requestDocument = operation
                    .requestBody
                    .flatMap { try document(from: $0) }
            } catch let err {
                print("===")
                print("-> " + String(describing: err))
                print("-- While parsing a request document for \(httpVerb.rawValue) at \(path.rawValue)")
                print("===")
                requestDocument = nil
            }

            let fullyQualifiedTestFuncNames = responseDocuments
                .values
                .compactMap { doc in
                    doc.testExampleFunc?
                        .functionName
            }.map {
                namespace(for: OpenAPI.PathComponents(path.components + [httpVerb.rawValue, "Response"]))
                    + "." + $0
            }

            return (
                httpVerb: httpVerb,
                path: path,
                pathItem: pathItem,
                documentFileNameString: documentFileNameString,
                apiRequestTest: apiRequestTest,
                requestDocument: requestDocument,
                responseDocuments: responseDocuments,
                fullyQualifiedTestFuncNames: fullyQualifiedTestFuncNames
            )
        }
    }

    for result in results {
        writeResourceObjectFiles(toPath: resourceObjDir + "/\(result.documentFileNameString)_response_",
            for: result.responseDocuments.values,
            extending: namespace(for: OpenAPI.PathComponents(result.path.components + [result.httpVerb.rawValue, "Response"])))

        if let reqDoc = result.requestDocument {
            writeResourceObjectFiles(toPath: resourceObjDir + "/\(result.documentFileNameString)_request_",
                for: [reqDoc],
                extending: namespace(for: OpenAPI.PathComponents(result.path.components + [result.httpVerb.rawValue, "Request"])))
        }

        // write API file
        writeAPIFile(toPath: testDir + "/\(result.documentFileNameString)_",
            for: result.apiRequestTest,
            reqDoc: result.requestDocument,
            respDocs: result.responseDocuments.values,
            httpVerb: result.httpVerb,
            extending: namespace(for: result.path))
    }

    let testClassFileContents = XCTestClassSwiftGen(className: "GeneratedTests",
                                                    importNames: [],
                                                    forwardingFullyQualifiedTestNames: results.flatMap { $0.fullyQualifiedTestFuncNames })
    write(contents: try! testClassFileContents.formattedSwiftCode(),
          toFileAt: testDir + "/",
          named: "GeneratedTests.swift")
}

enum HttpDirection: String {
    case request
    case response
}

func swiftTypeName(from string: String) -> String {
    return string
        .replacingOccurrences(of: "{", with: "")
        .replacingOccurrences(of: "}", with: "")
        .replacingOccurrences(of: " ", with: "_")
}

func namespace(for path: OpenAPI.PathComponents) -> String {
    return path.components
        .map(swiftTypeName)
        .joined(separator: ".")
}

func documentTypeName(path: OpenAPI.PathComponents,
                      verb: HttpVerb) -> String {
    let pathSnippet = swiftTypeName(from: path.components
        .joined(separator: "_"))

    return [pathSnippet, verb.rawValue].joined(separator: "_")
}

func writeResourceObjectFiles<T: Sequence>(toPath path: String,
                              for documents: T,
                              extending namespace: String) where T.Element == DataDocumentSwiftGen {
    for document in documents {

        let resourceObjectGenerators = document.resourceObjectGenerators

        let definedResourceObjectNames = Set(resourceObjectGenerators
            .map { $0.swiftTypeName })

        resourceObjectGenerators
            .forEach { resourceObjectGen in

                resourceObjectGen
                    .relationshipStubGenerators
                    .filter { !definedResourceObjectNames.contains($0.swiftTypeName) }
                    .forEach { stubGen in

                        // write relationship stub files
                        writeFile(toPath: path,
                                  for: stubGen,
                                  extending: namespace)
                }

                // write resource object files
                writeFile(toPath: path,
                          for: resourceObjectGen,
                          extending: namespace)
        }
    }
}

/// Take the API request and request documents and response documents
/// and wrap them in a nested namespace structure.
///
/// Example:
/// ```
/// enum GET {
///     func test_request(...) { ... }
///
///     enum Request {
///         typealias Document = ...
///     }
///     enum Response {
///         typealias Document_200 = ...
///         typealias Document_201 = ...
///     }
/// }
/// ```
func apiDocumentsBlock<T: Sequence>(request: APIRequestTestSwiftGen?,
                                    requestDoc: DataDocumentSwiftGen?,
                                    responseDocs: T,
                                    httpVerb: HttpVerb) -> Decl where T.Element == DataDocumentSwiftGen {
    let requestDocAndExample = requestDoc.map { doc in
        doc.decls
            + (doc.exampleGenerator?.decls ?? [])
            + (doc.testExampleFunc?.decls ?? [])
    }

    let requestBlock = requestDocAndExample
        .map {
            BlockTypeDecl.enum(typeName: "Request",
                               conformances: nil,
                               $0)
    }

    let responseDocsAndExamples = responseDocs.flatMap { doc in
        doc.decls
            + (doc.exampleGenerator?.decls ?? [])
            + (doc.testExampleFunc?.decls ?? [])
    }

    let responseBlock = BlockTypeDecl.enum(typeName: "Response",
                                           conformances: nil,
                                           responseDocsAndExamples)

    let verbBlock = BlockTypeDecl.enum(typeName: httpVerb.rawValue,
                                       conformances: nil,
                                       [requestBlock, responseBlock].compactMap { $0 } + (request?.decls ?? []))

    return verbBlock
}

/*
 print("===")
 print("-> " + String(describing: error))
 print("-- While creating \(httpVerb.rawValue) example test function.")
 print("===")
 */

extension Decl {
    func extending(namespace: String) -> Decl {
        return BlockTypeDecl.extension(typeName: namespace,
                                       conformances: nil,
                                       conditions: nil,
                                       [self])
    }
}

func writeAPIFile<T: Sequence>(toPath path: String,
                               for request: APIRequestTestSwiftGen?,
                               reqDoc: DataDocumentSwiftGen?,
                               respDocs: T,
                               httpVerb: HttpVerb,
                               extending namespace: String) where T.Element == DataDocumentSwiftGen {

    let apiDecl = apiDocumentsBlock(request: request,
                                    requestDoc: reqDoc,
                                    responseDocs: respDocs,
                                    httpVerb: httpVerb)
        .extending(namespace: namespace)

    let outputFileContents = try! [
        Import(module: "Foundation") as Decl,
        Import(module: "JSONAPI") as Decl,
        Import(module: "AnyCodable") as Decl,
        Import(module: "XCTest") as Decl,
        apiDecl
        ].map { try $0.formattedSwiftCode() }
        .joined(separator: "")

    write(contents: outputFileContents,
          toFileAt: path,
          named: "API.swift")
}

func writeFile<T: TypedSwiftGenerator>(toPath path: String,
                                       for resourceObject: T,
                                       extending namespace: String) {

    let swiftTypeName = resourceObject.swiftTypeName

    let decl = BlockTypeDecl.extension(typeName: namespace,
                                       conformances: nil,
                                       conditions: nil,
                                       resourceObject.decls)

    let outputFileContents = try! ([
        Import(module: "JSONAPI"),
        decl
        ] as [Decl])
        .map { try $0.formattedSwiftCode() }
        .joined(separator: "\n")

    write(contents: outputFileContents,
          toFileAt: path,
          named: "\(swiftTypeName).swift")
}

func write(contents: String, toFileAt path: String, named name: String) {
    try! contents
        .write(toFile: path + name,
               atomically: true,
               encoding: .utf8)
}

struct DeclNode: Equatable {
    let name: String
    var children: [DeclNode]

    var enumDecl: Decl {
        return BlockTypeDecl.enum(typeName: name,
                                  conformances: nil,
                                  children.map { $0.enumDecl })
    }
}

func namespaceDecls(for pathItems: OpenAPI.PathItem.Map) -> [DeclNode] {
    var paths = [DeclNode]()
    for (path, _) in pathItems {
        var remainingPath = path.components.makeIterator()

        func fillFrom(currentNode: inout DeclNode) {
            guard let next = remainingPath.next().map(swiftTypeName) else {
                return
            }
            var newNode = DeclNode(name: next, children: [])
            fillFrom(currentNode: &newNode)

            currentNode.children.append(newNode)
        }

        func step(currentNodes: inout [DeclNode]) {

            guard let next = remainingPath.next().map(swiftTypeName) else {
                return
            }

            if let idx = currentNodes.firstIndex(where: { $0.name == next }) {
                step(currentNodes: &currentNodes[idx].children)
            } else {
                var newNode = DeclNode(name: next, children: [])
                fillFrom(currentNode: &newNode)
                currentNodes.append(newNode)
            }
        }

        step(currentNodes: &paths)
    }
    return paths
}

func documents(from responses: OpenAPI.Response.Map,
               for httpVerb: HttpVerb,
               at path: OpenAPI.PathComponents,
               on server: OpenAPI.Server,
               given params: [OpenAPI.PathItem.Parameter]) -> [OpenAPI.Response.StatusCode: DataDocumentSwiftGen] {
    var responseDocuments = [OpenAPI.Response.StatusCode: DataDocumentSwiftGen]()
    for (statusCode, response) in responses {

        guard let jsonResponse = response.a?.content[.json] else {
            continue
        }

        guard let responseSchema = jsonResponse.schema.b else {
            continue
        }

        let responseBodyTypeName = "Document_\(statusCode.rawValue)"
        let examplePropName = "example_\(statusCode.rawValue)"

        let example: ExampleSwiftGen?
        do {
            example = try jsonResponse.example.map { try ExampleSwiftGen.init(openAPIExample: $0, propertyName: examplePropName) }
        } catch let err {
            print("===")
            print("-> " + String(describing: err))
            print("-- While parsing a response document for \(httpVerb.rawValue) at \(path.rawValue)")
            print("===")
            example = nil
        }

        let testExampleFunc: OpenAPIExampleTestSwiftGen?
        do {
            if let parameterValues = jsonResponse.vendorExtensions["x-testParameters"]?.value as? OpenAPI.PathItem.Parameter.ValueMap,
                example != nil {

                testExampleFunc = try OpenAPIExampleTestSwiftGen(server: server,
                                                                 pathComponents: path,
                                                                 parameters: params,
                                                                 parameterValues: parameterValues,
                                                                 exampleResponseDataPropName: examplePropName,
                                                                 responseBodyType: .def(.init(name: responseBodyTypeName)),
                                                                 expectedHttpStatus: statusCode)
            } else {
                testExampleFunc = nil
            }
        } catch let err {
            print("===")
            print("-> " + String(describing: err))
            print("-- While parsing a response document for \(httpVerb.rawValue) at \(path.rawValue)")
            print("===")
            testExampleFunc = nil
        }

        guard case .object = responseSchema else {
            print("Found non-object response schema root (expected JSON:API 'data' object). Skipping \(String(describing: responseSchema.jsonTypeFormat?.jsonType)).")
            continue
        }

        do {
            responseDocuments[statusCode] = try DataDocumentSwiftGen(swiftTypeName: responseBodyTypeName,
                                                                     structure: responseSchema,
                                                                     example: example,
                                                                     testExampleFunc: testExampleFunc)
        } catch let err {
            print("===")
            print("-> " + String(describing: err))
            print("-- While parsing a response document for \(httpVerb.rawValue) at \(path.rawValue)")
            print("===")
            continue
        }
    }
    return responseDocuments
}

func document(from request: OpenAPI.Request) throws -> DataDocumentSwiftGen? {
    guard let requestSchema = request.content[.json]?.schema.b else {
        return nil
    }

    guard case .object = requestSchema else {
        print("Found non-object request schema root (expected JSON:API 'data' object). Skipping \(String(describing: requestSchema.jsonTypeFormat?.jsonType))")
        return nil
    }

    // TODO: request examples

    return try DataDocumentSwiftGen(swiftTypeName: "Document",
                                    structure: requestSchema)
}

let packageFile: String = """
// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "GeneratedAPITests",
    products: [],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .upToNextMinor(from: "0.2.2")),
            .package(url: "https://github.com/mattpolzin/JSONAPI.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .testTarget(
            name: "GeneratedAPITests",
            dependencies: ["JSONAPI", "AnyCodable"]
        )
    ]
)
"""

let linuxMainFile: String = """
import XCTest

import GeneratedAPITests

XCTMain([
    testCase(GeneratedTests.allTests)
])
"""
