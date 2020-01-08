//
//  JSONAPI+Sampleable.swift
//  JSONAPIOpenAPI
//
//  Created by Mathew Polzin on 1/24/19.
//

import JSONAPI
import Sampleable

extension NoAttributes: Sampleable {
	public static var sample: NoAttributes {
		return .none
	}
}

extension NoRelationships: Sampleable {
	public static var sample: NoRelationships {
		return .none
	}
}

extension NoMetadata: Sampleable {
	public static var sample: NoMetadata {
		return .none
	}
}

extension NoLinks: Sampleable {
	public static var sample: NoLinks {
		return .none
	}
}

extension NoAPIDescription: Sampleable {
	public static var sample: NoAPIDescription {
		return .none
	}
}

extension UnknownJSONAPIError: Sampleable {
	public static var sample: UnknownJSONAPIError {
		return .unknownError
	}
}

extension Unidentified: Sampleable {
	public static var sample: Unidentified {
		return Unidentified()
	}
}

extension Attribute: Sampleable, AbstractSampleable where RawValue: Sampleable {
	public static var sample: Attribute<RawValue> {
		return .init(value: RawValue.sample)
	}
}

extension SingleResourceBody: Sampleable, AbstractSampleable where PrimaryResource: Sampleable {
	public static var sample: SingleResourceBody<PrimaryResource> {
		return .init(resourceObject: PrimaryResource.sample)
	}
}

extension ManyResourceBody: Sampleable, AbstractSampleable where PrimaryResource: Sampleable {
	public static var sample: ManyResourceBody<PrimaryResource> {
		return .init(resourceObjects: PrimaryResource.samples)
	}
}
