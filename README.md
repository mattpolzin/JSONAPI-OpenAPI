# JSONAPI+OpenAPI
[![MIT license](http://img.shields.io/badge/license-MIT-lightgrey.svg)](http://opensource.org/licenses/MIT) [![Swift 5.1/5.2](http://img.shields.io/badge/Swift-5.1/5.2-blue.svg)](https://swift.org) [![Build Status](https://app.bitrise.io/app/2ae0b5578e1905b8/status.svg?token=T8UAUN08e1_GnYk1z3P98g&branch=master)](https://app.bitrise.io/app/2ae0b5578e1905b8)

See parent project: https://github.com/mattpolzin/JSONAPI

The `JSONAPIOpenAPI` framework adds the ability to generate OpenAPI compliant JSON Schema documentation of a JSONAPI Document.

There is experimental support for generating `JSONAPI` Swift code from OpenAPI documentation in the JSONAPISwiftGen module. There is no formal documentation for this functionality, but it is an area of interest of mine. Reach out to me directly if you would like to know more.

See the Open API Spec here: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md

*This library has many loose ends and very little documentation. The documentation will grow as the framework becomes more complete.*

## Running and Testing
As of this writing, you need to run `swift package generate-xcodeproj` and then open that project in Xcode. Using Xcode's built-in Swift Package Manager support is currently broken for libraries like swift-syntax that require dynamic libraries from the Swift toolchain. `swift build`, `swift test`, etc. from the command line will work fine, though.

## _Experimental_ Swift Code Generation

The JSONAPISwiftGen module has experimental support for generating Swift code for `JSONAPI` models. You can dig into the source code or reach out to me for more information. This module is used by the API Test server project at [mattpolzin/jsonapi-openapi-test-server](https://github.com/mattpolzin/jsonapi-openapi-test-server) to generate models and tests.

## _Experimental_ Graphviz (DOT) Generation

The JSONAPIVizGen module has experimental support for generating Graphviz DOT files that graph out the models and relationships represented by the JSON:API/OpenAPI input. You can dig into the source code or reach out to me for more information.

## OpenAPI JSON Schema Generation
### Simple Example
You can try this out in the included Playground.

```swift
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
let widgetJSONSchema = Widget.openAPISchema(using: encoder)

//
// Describe a JSON:API response body with 1 widget and
// any number of related widgets included.
//
typealias SingleWidgetDocumentWithIncludes = Document<SingleResourceBody<Widget>, NoMetadata, NoLinks, Include1<Widget>, NoAPIDescription, BasicJSONAPIError<String>>

//
// Finally we can create a JSON Schema for the response body of a successful request
//
let jsonAPIResponseSchema = SingleWidgetDocumentWithIncludes.SuccessDocument.openAPISchema(using: encoder)

print(String(data: try! encoder.encode(jsonAPIResponseSchema), encoding: .utf8)!)

//
// Or a failed request
//
let jsonAPIResponseErrorSchema = SingleWidgetDocumentWithIncludes.ErrorDocument.openAPISchema(using: encoder)

//
// Or a schema describing the response as `oneOf` the success or error respones
//
let jsonAPIResponseFullSchema = SingleWidgetDocumentWithIncludes.openAPISchema(using: encoder)
```

The above code produces:
```json
{
  "type" : "object",
  "properties" : {
    "data" : {
      "type" : "object",
      "properties" : {
        "relationships" : {
          "type" : "object",
          "properties" : {
            "subcomponents" : {
              "type" : "object",
              "properties" : {
                "data" : {
                  "type" : "array",
                  "items" : {
                    "type" : "object",
                    "properties" : {
                      "type" : {
                        "type" : "string",
                        "enum" : [
                          "widgets"
                        ]
                      },
                      "id" : {
                        "type" : "string"
                      }
                    },
                    "required" : [
                      "id",
                      "type"
                    ]
                  }
                }
              },
              "required" : [
                "data"
              ]
            }
          },
          "required" : [
            "subcomponents"
          ]
        },
        "id" : {
          "type" : "string"
        },
        "type" : {
          "type" : "string",
          "enum" : [
            "widgets"
          ]
        },
        "attributes" : {
          "type" : "object",
          "properties" : {
            "productName" : {
              "type" : "string"
            }
          },
          "required" : [
            "productName"
          ]
        }
      },
      "required" : [
        "attributes",
        "id",
        "relationships",
        "type"
      ]
    },
    "included" : {
      "type" : "array",
      "items" : {
        "type" : "object",
        "properties" : {
          "relationships" : {
            "type" : "object",
            "properties" : {
              "subcomponents" : {
                "type" : "object",
                "properties" : {
                  "data" : {
                    "type" : "array",
                    "items" : {
                      "type" : "object",
                      "properties" : {
                        "type" : {
                          "type" : "string",
                          "enum" : [
                            "widgets"
                          ]
                        },
                        "id" : {
                          "type" : "string"
                        }
                      },
                      "required" : [
                        "type",
                        "id"
                      ]
                    }
                  }
                },
                "required" : [
                  "data"
                ]
              }
            },
            "required" : [
              "subcomponents"
            ]
          },
          "id" : {
            "type" : "string"
          },
          "type" : {
            "type" : "string",
            "enum" : [
              "widgets"
            ]
          },
          "attributes" : {
            "type" : "object",
            "properties" : {
              "productName" : {
                "type" : "string"
              }
            },
            "required" : [
              "productName"
            ]
          }
        },
        "required" : [
          "attributes",
          "id",
          "relationships",
          "type"
        ]
      },
      "uniqueItems" : true
    }
  },
  "required" : [
    "included",
    "data"
  ]
}
```
