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

func produceSwiftForDocuments(in pathItems: OpenAPI.PathItem.Map,
                              originatingAt server: OpenAPI.Server,
                              outputTo outPath: String) {

    // generate namespaces first
    let contents = try! namespaceDecls(for: pathItems)
        .map { try $0.enumDecl.formattedSwiftCode() }
        .joined(separator: "\n\n")
    write(contents: contents,
          toFileAt: outPath + "/" ,
          named: "Namespaces.swift")

    for httpVerb in HttpVerb.allCases {

        for (path, pathItem) in pathItems {
            guard case let .operations(operations) = pathItem else {
                continue
            }

            guard let operation = operations.for(httpVerb) else {
                continue
            }

            let documentFileNameString = documentTypeName(path: path, verb: httpVerb)

            let parameters = operation.parameters

            let apiRequest = try? APIRequestSwiftGen(server: server,
                                                     pathComponents: path,
                                                     parameters: parameters.compactMap { $0.a })

            let responses = operation.responses
            let responseDocuments = documents(from: responses, for: httpVerb, at: path)

            writeResourceObjectFiles(toPath: outPath + "/resourceObjects/\(documentFileNameString)_response_",
                                     for: responseDocuments.values,
                                     extending: namespace(for: OpenAPI.PathComponents(path.components + [httpVerb.rawValue, "Response"])))

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

            if let reqDoc = requestDocument {
                writeResourceObjectFiles(toPath: outPath + "/resourceObjects/\(documentFileNameString)_request_",
                                         for: [reqDoc],
                                         extending: namespace(for: OpenAPI.PathComponents(path.components + [httpVerb.rawValue, "Request"])))
            }

            // write API file
            writeAPIFile(toPath: outPath + "/\(documentFileNameString)_",
                for: apiRequest,
                reqDoc: requestDocument,
                respDocs: responseDocuments.values,
                httpVerb: httpVerb,
                extending: namespace(for: path))
        }
    }
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
func apiDocumentsBlock<T: Sequence>(request: APIRequestSwiftGen?,
                                    requestDoc: DataDocumentSwiftGen?,
                                    responseDocs: T,
                                    httpVerb: HttpVerb) -> Decl where T.Element == DataDocumentSwiftGen {
    let requestBlock = requestDoc.map { BlockTypeDecl.enum(typeName: "Request",
                                                           conformances: nil,
                                                           $0.decls) }
    let responseBlock = BlockTypeDecl.enum(typeName: "Response",
                                           conformances: nil,
                                           responseDocs.flatMap { $0.decls })

    let verbBlock = BlockTypeDecl.enum(typeName: httpVerb.rawValue,
                                       conformances: nil,
                                       [requestBlock, responseBlock].compactMap { $0 } + (request?.decls ?? []))

    return verbBlock
}

extension Decl {
    func extending(namespace: String) -> Decl {
        return BlockTypeDecl.extension(typeName: namespace,
                                       conformances: nil,
                                       conditions: nil,
                                       [self])
    }
}

func writeAPIFile<T: Sequence>(toPath path: String,
                               for request: APIRequestSwiftGen?,
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

func documents(from responses: OpenAPI.Response.Map, for httpVerb: HttpVerb, at path: OpenAPI.PathComponents) -> [OpenAPI.Response.StatusCode: DataDocumentSwiftGen] {
    var responseDocuments = [OpenAPI.Response.StatusCode: DataDocumentSwiftGen]()
    for (statusCode, response) in responses {

        guard let responseSchema = response.a?.content[.json]?.schema.b else {
            continue
        }

        guard case .object = responseSchema else {
            print("Found non-object response schema root (expected JSON:API 'data' object). Skipping \(String(describing: responseSchema.jsonTypeFormat?.jsonType)).")
            continue
        }

        do {
            responseDocuments[statusCode] = try DataDocumentSwiftGen(structure: responseSchema,
                                                                     swiftTypeName: "Document_\(statusCode.rawValue)")
        } catch {
            print("===")
            print("-> " + String(describing: error))
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

    return try DataDocumentSwiftGen(structure: requestSchema,
                                    swiftTypeName: "Document")
}
