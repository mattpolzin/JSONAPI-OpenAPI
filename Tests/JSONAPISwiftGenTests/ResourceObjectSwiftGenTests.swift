
import XCTest
import JSONAPISwiftGen
import JSONAPI
import Sampleable
import OpenAPIKit
import JSONAPIOpenAPI

let testEncoder = JSONEncoder()

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

    func test_ViaOpenAPI() {
        let openAPIStructure = try! TestPerson.openAPISchema(using: testEncoder)

        let testPersonSwiftGen = try! ResourceObjectSwiftGen(structure: openAPIStructure)

        XCTAssertEqual(testPersonSwiftGen.resourceTypeName, "TestPerson")

        print(try! testPersonSwiftGen.formattedSwiftCode())
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
        let friends: ToManyRelationship<TestPerson, NoMetadata, NoLinks>
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
