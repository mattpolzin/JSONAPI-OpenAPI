
import XCTest
import JSONAPISwiftGen
import JSONAPI
import Sampleable
import OpenAPIKit
import JSONAPIOpenAPI

let testEncoder = JSONEncoder()
let testDecoder = JSONDecoder()

class ResourceObjectSwiftGenTests: XCTestCase {
    func test_DirectConstruction() {
        let personDescription = BlockTypeDecl.enum(
            typeName: "PersonDescription",
            conformances: ["JSONAPI.ResourceObjectDescription"],
            [
                StaticDecl(.let(propName: "jsonType", swiftType: .init(String.self), "\"people\"")),
                BlockTypeDecl.struct(
                    typeName: "Attributes",
                    conformances: ["JSONAPI.Attributes"],
                    [
                        PropDecl.let(propName: "firstName", swiftType: .init(Attribute<String>.self), nil),
                        PropDecl.let(propName: "lastName", swiftType: .init(Attribute<String>.self), nil),
                        PropDecl.let(propName: "optional", swiftType: .init(Attribute<String?>.self), nil),
                        PropDecl.let(propName: "omittable", swiftType: .init(Attribute<String>?.self), nil)
                    ]
                ),
                BlockTypeDecl.struct(
                    typeName: "Relationships",
                    conformances: ["JSONAPI.Relationships"],
                    [
                        PropDecl.let(
                            propName: "friends",
                            swiftType: .init(
                                SwiftTypeDef(
                                    name: "ToManyRelationship",
                                    specializationReps: [
                                        "Person",
                                        .init(NoMetadata.self),
                                        .init(NoLinks.self)
                                    ]
                                )
                            ),
                            nil
                        )
                    ]
                )
            ]
        )
        let person = Typealias(alias: .init("Person"), existingType: .init(SwiftTypeDef(name: "JSONAPI.ResourceObject",
                                                                                        specializationReps: [
                                                                                            "PersonDescription",
                                                                                            .init(NoMetadata.self),
                                                                                            .init(NoLinks.self),
                                                                                            .init(String.self)
            ])))

        print(try! personDescription.formattedSwiftCode())
        print(try! person.formattedSwiftCode())
    }

    func test_ViaOpenAPI() throws {
        let openAPIStructure = try TestPerson.openAPISchema(using: testEncoder).dereferenced()!

        let testPersonSwiftGen = try ResourceObjectSwiftGen(structure: openAPIStructure)

        XCTAssertEqual(testPersonSwiftGen.resourceTypeName, "TestPerson")

        print(try testPersonSwiftGen.formattedSwiftCode())
    }

    func test_polyAttribute() throws {
        // test oneOf in simplest case
        let openAPIStructure = try testDecoder.decode(
            JSONSchema.self,
            from: """
            {
                "type": "object",
                "properties": {
                    "type": {"type": "string", "enum": ["poly_thing"]},
                    "id": {"type": "string"},
                    "attributes": {
                        "type": "object",
                        "properties": {
                            "poly_property": {
                                "oneOf" : [
                                    {"type": "string"},
                                    {"type": "number"},
                                    {"type": "array", "items": {"type": "string"}},
                                    {
                                        "type": "object",
                                        "properties": {
                                            "foo": {"type": "string", "format": "date"},
                                            "bar": {"type": "object"}
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        ).dereferenced()!

        let polyAttrSwiftGen = try ResourceObjectSwiftGen(structure: openAPIStructure)

        XCTAssertEqual(polyAttrSwiftGen.resourceTypeName, "PolyThing")

        print(polyAttrSwiftGen.swiftCode)
    }

    func test_polyAttribute2() throws {
        // test oneOf with type & nullable at root
        let openAPIStructure = try testDecoder.decode(
            JSONSchema.self,
            from: """
            {
                "type": "object",
                "properties": {
                    "type": {"type": "string", "enum": ["poly_thing"]},
                    "id": {"type": "string"},
                    "attributes": {
                        "type": "object",
                        "properties": {
                            "poly_property": {
                                "type": "object",
                                "nullable": true,
                                "oneOf": [
                                    {
                                        "type": "object",
                                        "title": "Widget",
                                        "additionalProperties": false,
                                        "nullable": true,
                                        "required": [
                                            "prop"
                                        ],
                                        "properties": {
                                            "prop": {
                                                "type": "string",
                                                "enum": [
                                                    "yes",
                                                    "no"
                                                ]
                                            },
                                            "reasoning": {
                                                "type": "string",
                                                "nullable": true
                                            }
                                        }
                                    },
                                    {
                                        "type": "object",
                                        "title": "Cog",
                                        "additionalProperties": false,
                                        "required": [
                                            "built"
                                        ],
                                        "properties": {
                                            "built": {
                                                "type": "boolean"
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        ).dereferenced()!

        let polyAttrSwiftGen = try ResourceObjectSwiftGen(structure: openAPIStructure)

        XCTAssertEqual(polyAttrSwiftGen.resourceTypeName, "PolyThing")

        print(polyAttrSwiftGen.swiftCode)
    }

    func test_polyAttribute3() throws {
        // test anyOf as Poly
        let openAPIStructure = try testDecoder.decode(
            JSONSchema.self,
            from: """
            {
                "type": "object",
                "properties": {
                    "type": {"type": "string", "enum": ["poly_thing"]},
                    "id": {"type": "string"},
                    "attributes": {
                        "type": "object",
                        "properties": {
                            "poly_property": {
                                "type": "object",
                                "nullable": true,
                                "anyOf": [
                                    {
                                        "type": "object",
                                        "title": "Metadata 1",
                                        "additionalProperties": true,
                                        "nullable": true,
                                        "properties": {
                                            "title": {
                                                "type": "string",
                                                "description": "title"
                                            }
                                        }
                                    },
                                    {
                                        "type": "object",
                                        "title": "Metadata 2",
                                        "additionalProperties": true,
                                        "properties": {
                                            "title": {
                                                "type": "string",
                                                "description": "title"
                                            },
                                            "is_starred": {
                                                "type": "boolean"
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
            """.data(using: .utf8)!
        ).dereferenced()!

        let polyAttrSwiftGen = try ResourceObjectSwiftGen(structure: openAPIStructure)

        XCTAssertEqual(polyAttrSwiftGen.resourceTypeName, "PolyThing")

        print(polyAttrSwiftGen.swiftCode)
    }
}

enum TestPersonDescription: JSONAPI.ResourceObjectDescription {
    static var jsonType: String = "test_person"

    struct Attributes: JSONAPI.Attributes {
        let firstName: Attribute<String>
        let lastName: Attribute<String?>
        let favoriteNumber: Attribute<Int>?
    }

    struct Relationships: JSONAPI.Relationships {
        let friends: ToManyRelationship<TestPerson, NoIdMetadata, NoMetadata, NoLinks>
    }
}

typealias TestPerson = JSONAPI.ResourceObject<TestPersonDescription, NoMetadata, NoLinks, String>

extension TestPersonDescription.Attributes: Sampleable {
    static var sample: TestPersonDescription.Attributes {
        return .init(firstName: .init(value: "Matt"), lastName: .init(value: nil), favoriteNumber: nil)
    }
}

extension TestPersonDescription.Relationships: Sampleable {
    static var sample: TestPersonDescription.Relationships {
        return .init(friends: .init(ids: [.init(rawValue: "1234")]))
    }
}
