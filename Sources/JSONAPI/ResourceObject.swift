import Foundation

@dynamicMemberLookup
public struct ResourceObject<ID, Fieldset>: ResourceObjectIdentifiable
where
	ID: Hashable & CustomStringConvertible,
	Fieldset: ResourceObjectFieldSet
{
	public typealias Attributes = Fieldset.Attributes
	public typealias Relationships = Fieldset.Relationships

	private enum CodingKeys: String, CodingKey {
		case type, id, attributes, relationships
	}

	public let type: String = Fieldset.resourceObjectType

	public var id: ID
	public var attributes: Attributes
	public var relationships: Relationships

	public init(id: ID, attributes: Attributes, relationships: Relationships) {
		self.id = id
		self.attributes = attributes
		self.relationships = relationships
	}

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<Attributes, V>) -> V {
		get { self.attributes[keyPath: keyPath] }
		set { self.attributes[keyPath: keyPath] = newValue }
	}

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<Relationships, V>) -> V {
		get { self.relationships[keyPath: keyPath] }
		set { self.relationships[keyPath: keyPath] = newValue }
	}
}

extension ResourceObject where Attributes == Unit {
	public init(id: ID, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension ResourceObject where Relationships == Unit {
	public init(id: ID, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension ResourceObject: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}

extension ResourceObject: Decodable where ID: Decodable, Attributes: Decodable, Relationships: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decode(String.self, forKey: .type)

		if type != Fieldset.resourceObjectType {
			throw DecodingError.typeMismatch(
				Fieldset.self,
				DecodingError.Context(
					codingPath: [CodingKeys.type],
					debugDescription:
						"Resource type '\(type)' does not match expected type '\(Fieldset.resourceObjectType)'"
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

extension ResourceObject: Encodable where ID: Encodable, Attributes: Encodable, Relationships: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

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
