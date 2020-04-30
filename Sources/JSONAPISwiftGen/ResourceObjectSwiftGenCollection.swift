//
//  ResourceObjectSwiftGenCollection.swift
//  
//
//  Created by Mathew Polzin on 1/7/20.
//

import OpenAPIKit

public struct ResourceObjectSwiftGenCollection {
    public let resourceObjectGenerators: [ResourceObjectSwiftGen]

    public init(_ doc: OpenAPI.Document, testSuiteConfiguration: TestSuiteConfiguration) throws {
        let pathItems = doc.paths

        resourceObjectGenerators = OpenAPI.HttpVerb.allCases
            .flatMap { httpVerb in
                return pathItems.flatMap { (path, pathItem) -> [ResourceObjectSwiftGen] in
                    guard let operation = pathItem.for(httpVerb) else {
                        return []
                    }

                    let parameters = operation.parameters

                    let responses = operation.responses

                    // TODO: this is a mess. Set -> Array for no good reason.
                    return documents(
                        from: responses,
                        for: httpVerb,
                        at: path,
                        on: doc.servers.first!,
                        given: parameters.compactMap { $0.b },
                        testSuiteConfiguration: testSuiteConfiguration
                    ).values.flatMap { Array($0.resourceObjectGenerators) }
                }
        }

        // TODO: change error handling so that all thrown errors propogate (but might benefit from new error type to contextualize parsing errors better).
    }
}

func documents(
    from responses: OpenAPI.Response.Map,
    for httpVerb: OpenAPI.HttpVerb,
    at path: OpenAPI.Path,
    on server: OpenAPI.Server,
    given params: [OpenAPI.PathItem.Parameter],
    testSuiteConfiguration: TestSuiteConfiguration
) -> [OpenAPI.Response.StatusCode: DataDocumentSwiftGen] {
    var responseDocuments = [OpenAPI.Response.StatusCode: DataDocumentSwiftGen]()
    for (statusCode, response) in responses {

        guard let jsonResponse = response.b?.content[.json] else {
            continue
        }

        guard let responseSchema = jsonResponse.schema.b else {
            continue
        }

        guard case .object = responseSchema else {
            print("Found non-object response schema root (expected JSON:API 'data' object). Skipping '\(String(describing: responseSchema.jsonTypeFormat?.jsonType))'.")
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
            print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
            print("===")
            example = nil
        }

        let testExampleFuncs: [SwiftFunctionGenerator]
        do {
            let responseBodyType = SwiftTypeRep(.init(name: responseBodyTypeName))
            if let testPropertiesDict = jsonResponse.vendorExtensions["x-tests"]?.value as? [String: Any] {

                testExampleFuncs = try OpenAPIExampleRequestTestSwiftGen.TestProperties
                    .properties(for: testPropertiesDict, server: server)
                    .map { testProps in
                        try OpenAPIExampleRequestTestSwiftGen(
                            server: server,
                            pathComponents: path,
                            parameters: params,
                            testSuiteConfiguration: testSuiteConfiguration,
                            testProperties: testProps,
                            exampleResponseDataPropName: examplePropName,
                            responseBodyType: responseBodyType,
                            expectedHttpStatus: statusCode
                        )
                }
            } else if example != nil {
                testExampleFuncs = try [
                    OpenAPIExampleParseTestSwiftGen(
                        exampleDataPropName: examplePropName,
                        bodyType: responseBodyType,
                        exampleHttpStatusCode: statusCode
                    )
                ]
            } else {
                testExampleFuncs = []
            }
        } catch let err {
            print("===")
            print("-> " + String(describing: err))
            print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
            print("===")
            testExampleFuncs = []
        }

        do {
            responseDocuments[statusCode] = try DataDocumentSwiftGen(
                swiftTypeName: responseBodyTypeName,
                structure: responseSchema,
                example: example,
                testExampleFuncs: testExampleFuncs
            )
        } catch let err {
            print("===")
            print("-> " + String(describing: err))
            print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
            print("===")
            continue
        }
    }
    return responseDocuments
}
