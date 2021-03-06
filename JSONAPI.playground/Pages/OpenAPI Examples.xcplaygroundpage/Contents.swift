//: [Previous](@previous)

import Foundation
import JSONAPI
import OpenAPIKit
import JSONAPIOpenAPI

// print Entity Schema
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

let personSchemaData = try? encoder.encode(Person.openAPISchema(using: encoder))

print("Person Schema")
print("====")
print(personSchemaData.map { String(data: $0, encoding: .utf8)! } ?? "Schema Construction Failed")
print("====")

let dogDocumentSchemaData = try? encoder.encode(SingleDogDocument.SuccessDocument.openAPINodeWithExample(using: encoder))

print("Dog Document Schema")
print("====")
print(dogDocumentSchemaData.map { String(data: $0, encoding: .utf8)! } ?? "Schema Construction Failed")
print("====")

let batchPersonSchemaData = try? encoder.encode(BatchPeopleDocument.SuccessDocument.openAPINodeWithExample(using: encoder))

print("Batch Person Document Schema")
print("====")
print(batchPersonSchemaData.map { String(data: $0, encoding: .utf8)! } ?? "Schema Construction Failed")
print("====")

let tmp: [String: JSONSchema] = [
	"BatchPerson": try! BatchPeopleDocument.SuccessDocument.openAPINodeWithExample(using: encoder)
]

let components = OpenAPI.Components(schemas: tmp)

let batchPeopleRef = JSONReference.internal(.node(\OpenAPI.Components.schemas, named: "BatchPerson"))

let tmp2 = JSONSchema.reference(batchPeopleRef)

print("====")
print("====")
//print(String(data: try! encoder.encode(components), encoding: .utf8)!)
print(String(data: try! encoder.encode(tmp2), encoding: .utf8)!)
