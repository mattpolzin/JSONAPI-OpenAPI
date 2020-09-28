//
//  ResourceObjectSwiftGenCollection.swift
//  
//
//  Created by Mathew Polzin on 1/7/20.
//

import OpenAPIKit

public struct ResourceObjectSwiftGenCollection {
    public let resourceObjectGenerators: [ResourceObjectSwiftGen]

    public init(_ doc: DereferencedDocument, testSuiteConfiguration: TestSuiteConfiguration) throws {
        let pathItems = doc.paths

        resourceObjectGenerators = OpenAPI.HttpMethod.allCases
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
                        given: parameters,
                        testSuiteConfiguration: testSuiteConfiguration
                    ).values.flatMap { Array($0.resourceObjectGenerators) }
                }
        }

        // TODO: change error handling so that all thrown errors propogate (but might benefit from new error type to contextualize parsing errors better).
    }
}

func documents(
    from responses: DereferencedResponse.Map,
    for httpVerb: OpenAPI.HttpMethod,
    at path: OpenAPI.Path,
    on server: OpenAPI.Server,
    given params: [DereferencedParameter],
    testSuiteConfiguration: TestSuiteConfiguration
) -> [OpenAPI.Response.StatusCode: JSONAPIDocumentSwiftGen] {
    var responseDocuments = [OpenAPI.Response.StatusCode: JSONAPIDocumentSwiftGen]()
    for (statusCode, response) in responses {

        guard let jsonResponse = response.content[.json] else {
            continue
        }

        guard let responseSchema = jsonResponse.schema,
              case .object = responseSchema else {
            print("Found non-object response schema root (expected JSON:API 'data' object). Skipping '\(String(describing: jsonResponse.schema?.jsonTypeFormat?.jsonType))'.")
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

        let testExampleFuncs: [TestFunctionGenerator]
        do {
            let responseBodyType = SwiftTypeRep(.init(name: responseBodyTypeName))
            if let testPropertiesDict = jsonResponse.vendorExtensions["x-tests"]?.value as? [String: Any] {

                testExampleFuncs = try OpenAPIExampleRequestTestSwiftGen.TestProperties
                    .properties(for: testPropertiesDict, server: server)
                    .map { testProps in
                        try OpenAPIExampleRequestTestSwiftGen(
                            method: httpVerb,
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
            responseDocuments[statusCode] = try JSONAPIDocumentSwiftGen(
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
