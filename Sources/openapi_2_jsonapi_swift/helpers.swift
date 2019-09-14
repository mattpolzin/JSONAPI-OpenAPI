//
//  File.swift
//  
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import OpenAPIKit
import JSONAPISwiftGen

func produceSwiftForDocuments(in pathItems: OpenAPI.PathItem.Map, outputTo outPath: String) {

    // create namespaces first
    struct Node: Equatable {
        let name: String
        var children: [Node]

        var enumDecl: Decl {
            return BlockTypeDecl.enum(typeName: name,
                                      conformances: nil,
                                      children.map { $0.enumDecl })
        }
    }
    var paths = [Node]()
    for (path, _) in pathItems {
        var remainingPath = path.components.makeIterator()

        func fillFrom(currentNode: inout Node) {
            guard let next = remainingPath.next().map(swiftTypeName) else {
                return
            }
            var newNode = Node(name: next, children: [])
            fillFrom(currentNode: &newNode)

            currentNode.children.append(newNode)
        }

        func step(currentNodes: inout [Node]) {

            guard let next = remainingPath.next().map(swiftTypeName) else {
                return
            }

            if let idx = currentNodes.firstIndex(where: { $0.name == next }) {
                step(currentNodes: &currentNodes[idx].children)
            } else {
                var newNode = Node(name: next, children: [])
                fillFrom(currentNode: &newNode)
                currentNodes.append(newNode)
            }
        }

        step(currentNodes: &paths)
    }
    let contents = try! paths
        .map { try $0.enumDecl.formattedSwiftCode() }
        .joined(separator: "\n\n")
    write(contents: contents,
          toFileAt: outPath + "/" ,
          named: "Namespaces.swift")

    for (path, pathItem) in pathItems {
        guard case let .operations(operations) = pathItem else {
            continue
        }

        guard let responseSchemas = operations.get?.responses.values.compactMap({ $0.a?.content[.json]?.schema.b }) else {
            continue
        }

        var responseDocuments = [String: [DataDocumentSwiftGen]]()
        for responseSchema in responseSchemas {
            guard case .object = responseSchema else {
                print("Found non-object response schema root (expected JSON:API 'data' object). Skipping \(String(describing: responseSchema.jsonTypeFormat?.jsonType)).")
//                print(responseSchema)
                continue
            }

            let documentFileNameString = documentTypeName(path: path, verb: "get", direction: .response)

            do {
                responseDocuments[documentFileNameString, default: []].append(try DataDocumentSwiftGen(structure: responseSchema,
                                                                  swiftTypeName: "Response"))
            } catch {
                print("Failed to parse response document: ")
                print(error)
                continue
            }
        }

        for (pathString, responseDocuments) in responseDocuments {
            let httpVerb = "Get"

            let resourceObjectGenerators = responseDocuments
                .flatMap { $0.resourceObjectGenerators }

            let definedResourceObjectNames = Set(resourceObjectGenerators
                .map { $0.swiftTypeName })

            resourceObjectGenerators
                .forEach { resourceObjectGen in

                    resourceObjectGen
                        .relationshipStubGenerators
                        .filter { !definedResourceObjectNames.contains($0.swiftTypeName) }
                        .forEach { stubGen in

                            // write relationship stub files
                            writeFile(toPath: outPath + "/responses/\(pathString)_",
                                for: stubGen,
                                extending: namespace(for: OpenAPI.PathComponents(path.components + [httpVerb])))
                    }

                    // write resource object files
                    writeFile(toPath: outPath + "/responses/\(pathString)_",
                        for: resourceObjectGen,
                        extending: namespace(for: OpenAPI.PathComponents(path.components + [httpVerb])))
            }

            // write document files
            writeFile(toPath: outPath + "/responses/\(pathString)_",
                for: responseDocuments,
                extending: namespace(for: path),
                in: .enum(typeName: httpVerb, conformances: nil, []))
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
                      verb: String,
                      direction: HttpDirection) -> String {
    let pathSnippet = swiftTypeName(from: path.components
        .joined(separator: "_"))

    return [pathSnippet, verb, direction.rawValue].joined(separator: "_")
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

func writeFile(toPath path: String,
               for documents: [DataDocumentSwiftGen],
               extending namespace: String,
               in nestedBlock: BlockTypeDecl? = nil) {
    let outputFileContents = try! ([Import(module: "JSONAPI")] +
        (documents.map { document in
            BlockTypeDecl.extension(typeName: namespace,
                                        conformances: nil,
                                        conditions: nil,
                                        nestedBlock.map { nb in [nb.appending(document.decls)] } ?? document.decls)
        }) as [Decl])
        .map { try $0.formattedSwiftCode() }
        .joined(separator: "\n")

    write(contents: outputFileContents,
          toFileAt: path,
          named: "Response_Documents.swift")
}

func write(contents: String, toFileAt path: String, named name: String) {
    try! contents
        .write(toFile: path + name,
               atomically: true,
               encoding: .utf8)
}
