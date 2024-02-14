//
//  ResourceObjectSwiftGenCollection.swift
//  
//
//  Created by Mathew Polzin on 1/7/20.
//

import OpenAPIKit30

public struct ResourceObjectSwiftGenCollection {
    public let resourceObjectGenerators: [ResourceObjectSwiftGen]

    public init(
      _ doc: DereferencedDocument,
      testSuiteConfiguration: TestSuiteConfiguration,
      allowPlaceholders: Bool = true
    ) throws {
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
                        testSuiteConfiguration: testSuiteConfiguration,
                        allowPlaceholders: allowPlaceholders
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
    testSuiteConfiguration: TestSuiteConfiguration,
    allowPlaceholders: Bool
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

        var exampleGens = [ExampleSwiftGen]()
        var testExampleFuncs = [TestFunctionGenerator]()

        let responseBodyType = SwiftTypeRep(.init(name: responseBodyTypeName))

        // if there is 1 example, we also see about creating test cases from x-tests (which
        // don't yet support named examples, though that would be great).
        if let example = jsonResponse.example {
            let examplePropName = "example_\(statusCode.rawValue)"
            do {
                exampleGens.append(try ExampleSwiftGen.init(openAPIExample: example, propertyName: examplePropName))
            } catch let err {
                print("===")
                print("-> " + String(describing: err))
                print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
                print("===")
            }
            do {
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
                } else if !(exampleGens.isEmpty) {
                    testExampleFuncs.append(
                        try OpenAPIExampleParseTestSwiftGen(
                            exampleDataPropName: examplePropName,
                            bodyType: responseBodyType,
                            exampleHttpStatusCode: statusCode,
                            exampleName: "default"
                        )
                    )
                }
            } catch let err {
                print("===")
                print("-> " + String(describing: err))
                print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
                print("===")
            }
        } else if let examples = jsonResponse.examples?.mapValues({ $0.value?.b }) {
            // if there are multiple examples, we simply generate tests for each named example
            // because we don't yet support request-based testing for named examples.

            func exampleProp(named name: String) -> String {
                "example_\(statusCode.rawValue)_\(propertyCased(name))"
            }

            for (name, maybeExample) in examples {
                guard let example = maybeExample else { continue }
                let examplePropName = exampleProp(named: name)
                do {
                    exampleGens.append(try ExampleSwiftGen.init(openAPIExample: example, propertyName: examplePropName))
                } catch let err {
                    print("===")
                    print("-> " + String(describing: err))
                    print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
                    print("===")
                }
                do {
                    testExampleFuncs.append(
                        try OpenAPIExampleParseTestSwiftGen(
                            exampleDataPropName: examplePropName,
                            bodyType: responseBodyType,
                            exampleHttpStatusCode: statusCode,
                            exampleName: propertyCased(name)
                        )
                    )
                } catch let err {
                    print("===")
                    print("-> " + String(describing: err))
                    print("-- While parsing the HTTP \(statusCode.rawValue) response document for \(httpVerb.rawValue) at \(path.rawValue)")
                    print("===")
                }
            }
        }

        do {
            responseDocuments[statusCode] = try JSONAPIDocumentSwiftGen(
                swiftTypeName: responseBodyTypeName,
                structure: responseSchema,
                allowPlaceholders: allowPlaceholders,
                examples: exampleGens,
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
