# JSONAPI+OpenAPI
[![MIT license](http://img.shields.io/badge/license-MIT-lightgrey.svg)](http://opensource.org/licenses/MIT) [![Swift 5.1](http://img.shields.io/badge/Swift-5.1-blue.svg)](https://swift.org) [![Build Status](https://app.bitrise.io/app/2ae0b5578e1905b8/status.svg?token=T8UAUN08e1_GnYk1z3P98g&branch=master)](https://app.bitrise.io/app/2ae0b5578e1905b8)

See parent project: https://github.com/mattpolzin/JSONAPI

The `JSONAPIOpenAPI` framework adds the ability to generate OpenAPI compliant JSON Schema documentation of a JSONAPI Document.

There is experimental support for generating `JSONAPI` Swift code from OpenAPI documentation on the `feature/gen-swift` branch. There is no formal documentation for this functionality, but it is an area of interest of mine. Reach out to me directly if you would like to know more. 

See the Open API Spec here: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md

*This library is in its infancy. The documentation will grow as the framework becomes more complete.*

## _Experimental_ Swift Code Generation

The `feature/gen-swift` branch has experimental support for generating Swift code for `JSONAPI` models. You can dig into the source code or try out the included `openapi_2_jsonapi_swift` executable target. It takes 2 arguments; the file path of a complete OpenAPI Document and the directory to which all resulting files should be output. **IMPORTANT**: The output directory currently must contain a folder named "responses". It runs through the document looking for response payloads that are **JSON:API** compliant and pulling out all of the Resource Objects it finds to generate Swift code that would encode/decode data fitting the schemas. It also creates JSON:API Document aliases for `GET` response bodies and `test_request()` functions for `GET` requests.

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
let widgetJSONSchema = Widget.openAPINode(using: encoder)

//
// Describe a JSON:API response body with 1 widget and
// any number of related widgets included.
//
typealias SingleWidgetDocumentWithIncludes = Document<SingleResourceBody<Widget>, NoMetadata, NoLinks, Include1<Widget>, NoAPIDescription, BasicJSONAPIError<String>>

//
// Finally we can create a JSON Schema for the response body
//
let jsonAPIResponseSchema = SingleWidgetDocumentWithIncludes.openAPINode(using: encoder)

print(String(data: try! encoder.encode(jsonAPIResponseSchema), encoding: .utf8)!)
```

The above code produces:
```json
{
  "type" : "object",
  "properties" : {
    "data" : {
      "type" : "object",
      "properties" : {
        "id" : {
          "type" : "string"
        },
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
                      "id" : {
                        "type" : "string"
                      },
                      "type" : {
                        "type" : "string",
                        "enum" : [
                          "widgets"
                        ]
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
        "type",
        "relationships",
        "id"
      ]
    },
    "included" : {
      "type" : "array",
      "items" : {
        "type" : "object",
        "properties" : {
          "id" : {
            "type" : "string"
          },
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
          "type",
          "attributes",
          "relationships",
          "id"
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
