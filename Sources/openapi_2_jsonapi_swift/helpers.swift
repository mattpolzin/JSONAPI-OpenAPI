//
//  File.swift
//  
//
//  Created by Mathew Polzin on 7/27/19.
//

import Foundation
import OpenAPIKit
import JSONAPISwiftGen

func produceSwiftForResponsesAndIncludes(in pathItems: OpenAPI.PathItem.Map) {

    for pathItem in pathItems.values {
        guard case let .operations(operations) = pathItem else {
            continue
        }

        guard let responseSchemas = operations.get?.responses.values.compactMap({ $0.a?.content[.json]?.schema.b }) else {
            continue
        }

        for responseSchema in responseSchemas {
            guard case let .object(_, c2) = responseSchema else {
                print("Found non-object response schema root (expected JSON:API 'data' object). Skipping \(String(describing: responseSchema.jsonTypeFormat?.jsonType)).")
//                print(responseSchema)
                continue
            }

            guard let rootData = c2.properties["data"] else {
                print("Did not find root 'data' key as expected. Skipping object with properties \(String(describing: c2.properties.map { ($0.key, $0.value.jsonTypeFormat?.jsonType) })).")
                continue
            }

            let resourceObjectSchema: JSONSchema
            if case let .array(_, c4) = rootData,
                let items = c4.items,
                case .object = items {
                resourceObjectSchema = items
            } else if let item = c2.properties["data"],
                case .object = item {
                resourceObjectSchema = item
            } else {
                print("Did not find array or object within root 'data' key. Skipping \(String(describing: rootData.jsonTypeFormat?.jsonType)).")
//                print(c2)
                continue
            }

            produceSwift(for: resourceObjectSchema)

            guard case let .array(_, c6)? = c2.properties["included"],
                let items = c6.items,
                case let .one(of: includeResourceObjectSchemas) = items else {
                    continue
            }

            for include in includeResourceObjectSchemas {
                produceSwift(for: include)
            }
        }
    }
}

func produceSwift(for schema: JSONSchema) {
    let output = try! ResourceObjectSwiftGen(structure: schema)

    let swiftTypeName = output.swiftTypeName

    let outputFileContents = try! output.formattedSwiftCode()

    try! outputFileContents
        .write(toFile: filename + "_\(swiftTypeName).swift",
            atomically: true,
            encoding: .utf8)
}
