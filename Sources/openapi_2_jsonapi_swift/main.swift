
import OpenAPIKit
import JSONAPISwiftGen
import Foundation

let inFile = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]

let inputFileContents = try! Data(contentsOf: URL(fileURLWithPath: inFile))

let jsonDecoder = JSONDecoder()

let openAPIStructure = try! jsonDecoder.decode(OpenAPI.Document.self, from: inputFileContents)

let pathItems = openAPIStructure.paths

produceSwiftForDocuments(in: pathItems, outputTo: outPath)

print("Done.")
