//: [Previous](@previous)

import Foundation
import JSONAPI
import OpenAPIKit
import JSONAPIOpenAPI
import Poly

// print Entity Schema
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

let personSchemaData = try? encoder.encode(Person.openAPINode(using: encoder))

print("Person Schema")
print("====")
print(personSchemaData.map { String(data: $0, encoding: .utf8)! } ?? "Schema Construction Failed")
print("====")

let dogDocumentSchemaData = try? encoder.encode(SingleDogDocument.openAPINodeWithExample(using: encoder))

print("Dog Document Schema")
print("====")
print(dogDocumentSchemaData.map { String(data: $0, encoding: .utf8)! } ?? "Schema Construction Failed")
print("====")

let batchPersonSchemaData = try? encoder.encode(BatchPeopleDocument.openAPINodeWithExample(using: encoder))

print("Batch Person Document Schema")
print("====")
print(batchPersonSchemaData.map { String(data: $0, encoding: .utf8)! } ?? "Schema Construction Failed")
print("====")

let tmp: [String: JSONSchema] = [
	"BatchPerson": try! BatchPeopleDocument.openAPINodeWithExample(using: encoder)
]

let components = OpenAPI.Components(schemas: tmp,
                                    parameters: [:],
                                    headers: [:])

let batchPeopleRef = JSONReference.internal(.node(.init(type: \OpenAPI.Components.schemas, selector: "BatchPerson")))

let tmp2 = JSONSchema.reference(batchPeopleRef)

print("====")
print("====")
//print(String(data: try! encoder.encode(components), encoding: .utf8)!)
print(String(data: try! encoder.encode(tmp2), encoding: .utf8)!)
