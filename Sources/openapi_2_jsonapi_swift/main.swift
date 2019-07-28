
import OpenAPIKit
import JSONAPISwiftGen
import Foundation

let filename = CommandLine.arguments[1]

let inputFileContents = try! Data(contentsOf: URL(fileURLWithPath: filename))
//let inputFileContents = try! String(contentsOfFile: filename)

let jsonDecoder = JSONDecoder()

let openAPIStructure = try! jsonDecoder.decode(OpenAPI.Document.self, from: inputFileContents)

let pathItems = openAPIStructure.paths

produceSwiftForResponsesAndIncludes(in: pathItems)

print("Done.")
