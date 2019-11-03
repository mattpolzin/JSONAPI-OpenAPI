import Foundation
import JSONAPI
import JSONAPITesting // for the convenience of literal initialization
import JSONAPIOpenAPI
import SwiftCheck
import Sampleable

extension PersonDescription.Attributes: Sampleable {
	public static var sample: PersonDescription.Attributes {
		return .init(name: ["Abbie", "Eibba"], favoriteColor: "Blue")
	}
}

extension PersonDescription.Relationships: Sampleable {
	public static var sample: PersonDescription.Relationships {
		return .init(friends: ["1", "2"], dogs: ["2"], home: "1")
	}
}

extension DogDescription.Attributes: Sampleable {
	public static var sample: DogDescription.Attributes {
        return DogDescription.Attributes(name: "Sparky")
	}
}

extension DogDescription.Relationships: Sampleable {
	public static var sample: DogDescription.Relationships {
        return DogDescription.Relationships(owner: "1")
	}
}

private var counter = 1
extension Id: Sampleable where RawType == String {
    public static var sample: Id<RawType, IdentifiableType> {
        let id = "\(counter)"
        counter = counter + 1
        return .init(rawValue: id)
    }
}

extension JSONAPI.ResourceObject: Sampleable where Description.Attributes: Sampleable, Description.Relationships: Sampleable, MetaType: Sampleable, LinksType: Sampleable, EntityRawIdType == String {
    public static var sample: JSONAPI.ResourceObject<Description, MetaType, LinksType, EntityRawIdType> {
        return JSONAPI.ResourceObject(id: .sample,
                                      attributes: .sample,
                                      relationships: .sample,
                                      meta: .sample,
                                      links: .sample)
    }
}

extension Document: Sampleable where PrimaryResourceBody: Sampleable, IncludeType: Sampleable, MetaType: Sampleable, LinksType: Sampleable, Error: Sampleable, APIDescription: Sampleable {
	public static var sample: Document {
        return successSample!
	}

	public static var successSample: Document? {
        return Document(apiDescription: APIDescription.sample,
                        body: PrimaryResourceBody.sample,
                        includes: .init(values: IncludeType.samples),
                        meta: MetaType.sample,
                        links: LinksType.sample)
	}

	public static var failureSample: Document? {
        return Document(apiDescription: APIDescription.sample,
                        errors: Error.samples,
                        meta: MetaType.sample,
                        links: LinksType.sample)
	}
}
