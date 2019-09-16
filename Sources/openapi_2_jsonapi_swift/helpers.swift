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

            let responses = operation.responses
            let parameters = operation.parameters

            let apiRequest = try? APIRequestSwiftGen(server: server,
                                                     pathComponents: path,
                                                     parameters: parameters.compactMap { $0.a })

            let documentFileNameString = documentTypeName(path: path, verb: httpVerb, direction: .response)

            let responseDocuments = documents(from: responses)

            // write API file
            writeAPIFile(toPath: outPath + "/responses/\(documentFileNameString)_",
                for: apiRequest,
                and: responseDocuments.values,
                extending: namespace(for: path),
                in: .enum(typeName: httpVerb.rawValue, conformances: nil, []))

            writeResourceObjectFiles(toPath: outPath + "/responses/\(documentFileNameString)_",
                                     for: responseDocuments,
                                     extending: namespace(for: OpenAPI.PathComponents(path.components + [httpVerb.rawValue])))
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
                      verb: HttpVerb,
                      direction: HttpDirection) -> String {
    let pathSnippet = swiftTypeName(from: path.components
        .joined(separator: "_"))

    return [pathSnippet, verb.rawValue, direction.rawValue].joined(separator: "_")
}

func writeResourceObjectFiles(toPath path: String,
                              for responseDocuments: [OpenAPI.Response.StatusCode: DataDocumentSwiftGen],
                              extending namespace: String) {
    for (_, responseDocument) in responseDocuments {

        let resourceObjectGenerators = responseDocument.resourceObjectGenerators

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

func writeAPIFile<T: Sequence>(toPath path: String,
               for request: APIRequestSwiftGen?,
               and documents: T,
               extending namespace: String,
               in nestedBlock: BlockTypeDecl? = nil) where T.Element == DataDocumentSwiftGen {

    let decls = documents.flatMap { document in
        document.decls
    } + (request?.decls ?? [])

    let nestedDecl = nestedBlock.map { nb in [nb.appending(decls)] } ?? decls

    let contextBlock = BlockTypeDecl.extension(typeName: namespace,
                                               conformances: nil,
                                               conditions: nil,
                                               nestedDecl)

    let outputFileContents = try! [
        Import(module: "Foundation") as Decl,
        Import(module: "JSONAPI") as Decl,
        Import(module: "AnyCodable") as Decl,
        Import(module: "XCTest") as Decl,
        contextBlock as Decl
        ].map { try $0.formattedSwiftCode() }
        .joined(separator: "")

    write(contents: outputFileContents,
          toFileAt: path,
          named: "API.swift")
}

func writeFile<T: TypedSwiftGenerator>(toPath path: String,
                                       for resourceObject: T,
                                       extending namespace: String,
                                       in nestedBlock: BlockTypeDecl? = nil) {

    let swiftTypeName = resourceObject.swiftTypeName

    let outputFileContents = try! ([
        Import(module: "JSONAPI"),
        BlockTypeDecl.extension(typeName: namespace,
                                conformances: nil,
                                conditions: nil,
                                nestedBlock.map { nb in [nb.appending(resourceObject.decls)] } ?? resourceObject.decls)
        ] as [Decl])
        .map { try $0.formattedSwiftCode() }
        .joined(separator: "\n")

    write(contents: outputFileContents,
          toFileAt: path,
          named: "Response_\(swiftTypeName).swift")
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

func documents(from responses: OpenAPI.Response.Map) -> [OpenAPI.Response.StatusCode: DataDocumentSwiftGen] {
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
                                                                     swiftTypeName: "Response_\(statusCode.rawValue)")
        } catch {
            print("Failed to parse response document: ")
            print(error)
            continue
        }
    }
    return responseDocuments
}
