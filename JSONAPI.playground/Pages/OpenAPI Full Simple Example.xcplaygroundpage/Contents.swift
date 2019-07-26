//: [Previous](@previous)

import Foundation
import JSONAPI
import OpenAPIKit
import JSONAPIOpenAPI
import Sampleable

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

//
// First describe the resource object
//
struct WidgetDescription: JSONAPI.ResourceObjectDescription {
    static var jsonType: String { return "widgets" }

    struct Attributes: JSONAPI.Attributes {
        let productName: Attribute<String>
    }

    struct Relationships: JSONAPI.Relationships {
        let subcomponents: ToManyRelationship<Widget, NoMetadata, NoLinks>
    }
}

typealias Widget = JSONAPI.ResourceObject<WidgetDescription, NoMetadata, NoLinks, String>

//
// Then make things sampleable
// This is needed because the only way to use reflection on
// your attributes and relationships structs is to create
// instances of them.
//
extension WidgetDescription.Attributes: Sampleable {
    static var sample: WidgetDescription.Attributes {
        return .init(productName: .init(value: "Fillihizzer Nob Hub"))
    }
}

extension WidgetDescription.Relationships: Sampleable {
    static var sample: WidgetDescription.Relationships {
        return .init(subcomponents: .init(ids: [.init(rawValue: "1")]))
    }
}

//
// We can create a JSON Schema for the Widget at this point
//
let widgetJSONSchema = Widget.openAPINode(using: encoder)

//
// Describe a JSON:API response body with 1 widget and
// any number of related widgets included.
//
typealias SingleWidgetDocumentWithIncludes = Document<SingleResourceBody<Widget>, NoMetadata, NoLinks, Include1<Widget>, NoAPIDescription, UnknownJSONAPIError>

//
// Finally we can create a JSON Schema for the response body
//
let jsonAPIResponseSchema = SingleWidgetDocumentWithIncludes.openAPINode(using: encoder)

print(String(data: try! encoder.encode(jsonAPIResponseSchema), encoding: .utf8)!)
