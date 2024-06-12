import Foundation

public enum ResourceCodingKeys: String, CodingKey {
	case type, id, attributes, relationships
}

@dynamicMemberLookup
public struct Resource<ID, Definition>: ResourceDefinitionProviding, ResourceIdentifiable, ResourceLinkageProviding
where
	ID: Hashable & CustomStringConvertible,
	Definition: ResourceDefinition
{
	public typealias Attributes = Definition.Attributes
	public typealias Relationships = Definition.Relationships

	public let type: String = Definition.resourceType

	public let id: ID
	public let attributes: Attributes
	public let relationships: Relationships

	public init(id: ID, attributes: Attributes, relationships: Relationships) {
		self.id = id
		self.attributes = attributes
		self.relationships = relationships
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Attributes, V>) -> V {
		self.attributes[keyPath: keyPath]
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Relationships, V>) -> V {
		self.relationships[keyPath: keyPath]
	}
}

extension Resource where Attributes == Unit {
	public init(id: ID, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension Resource where Relationships == Unit {
	public init(id: ID, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension Resource where Attributes == Unit, Relationships == Unit {
	public init(id: ID) {
		self.init(id: id, attributes: Unit(), relationships: Unit())
	}
}

extension Resource: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}

extension Resource: Decodable where ID: Decodable, Attributes: Decodable, Relationships: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: ResourceCodingKeys.self)

		let type = try container.decode(String.self, forKey: .type)

		if type != Definition.resourceType {
			throw DecodingError.typeMismatch(
				Definition.self,
				DecodingError.Context(
					codingPath: [ResourceCodingKeys.type],
					debugDescription:
						"Resource type '\(type)' does not match expected type '\(Definition.resourceType)'"
				)
			)
		}

		self.id = try container.decode(ID.self, forKey: .id)

		if let attributes = Unit() as? Attributes {
			self.attributes = attributes
		} else {
			self.attributes = try container.decode(Attributes.self, forKey: .attributes)
		}

		if let relationships = Unit() as? Relationships {
			self.relationships = relationships
		} else {
			self.relationships = try container.decode(Relationships.self, forKey: .relationships)
		}
	}
}

extension Resource: Encodable where ID: Encodable, Attributes: Encodable, Relationships: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: ResourceCodingKeys.self)

		try container.encode(self.type, forKey: .type)
		try container.encode(self.id, forKey: .id)

		if Attributes.self != Unit.self {
			try container.encode(self.attributes, forKey: .attributes)
		}

		if Relationships.self != Unit.self {
			try container.encode(self.relationships, forKey: .relationships)
		}
	}
}
