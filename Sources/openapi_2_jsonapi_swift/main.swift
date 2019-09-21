
import OpenAPIKit
import JSONAPISwiftGen
import Foundation

let inFile = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]

if !FileManager.default.fileExists(atPath: outPath + "/resourceObjects") {
    try! FileManager.default.createDirectory(atPath: outPath + "/resourceObjects",
                                             withIntermediateDirectories: false,
                                             attributes: nil)
}

let inputFileContents = try! Data(contentsOf: URL(fileURLWithPath: inFile))

let jsonDecoder = JSONDecoder()

let openAPIStructure = try! jsonDecoder.decode(OpenAPI.Document.self, from: inputFileContents)

let pathItems = openAPIStructure.paths

produceSwiftForDocuments(in: pathItems,
                         originatingAt: openAPIStructure.servers.first!,
                         outputTo: outPath)

print("Done.")

/*
 VALIDATION IDEAS:
 1. When a path parameter is specified in path component but not in parameters.
 2. When a path parameter is specified in parameters but does not appear in path components.
 3. When different endpoints define different resources objects with the same JSON:API type.
 */

/*
 IMPROVEMENTS:
 1. Create RawRepresentable enums for OpenAPI components that specify enumerated options (like string params or attributes)
 */
