//
//  JSONAPISwiftGen+JSONAPIViz.swift
//  
//
//  Created by Mathew Polzin on 1/7/20.
//

import JSONAPISwiftGen
import JSONAPIViz

extension JSONAPISwiftGen.Relative.Relationship {
    public var vizRelationship: JSONAPIViz.Relationship {
        switch self {
        case .toMany(.required):
            return .toMany(.required)
        case .toMany(.optional):
            return .toMany(.optional)
        case .toOne(.required):
            return .toOne(.required)
        case .toOne(.optional):
            return .toOne(.optional)
        }
    }
}

extension JSONAPISwiftGen.Relative: JSONAPIViz.RelativeType {
    public var name: String {
        propertyName
    }

    public var typeName: String {
        swiftTypeName
    }

    public var relationship: JSONAPIViz.Relationship {
        relationshipType.vizRelationship
    }
}

extension ResourceObjectSwiftGen: JSONAPIViz.ResourceType {
    public var typeName: String {
        resourceTypeName
    }
}
