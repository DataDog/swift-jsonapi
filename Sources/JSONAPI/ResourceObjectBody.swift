import Foundation

@dynamicMemberLookup
public struct ResourceObjectBody<ID, FieldSet>: Encodable
where
	ID: Hashable & Encodable,
	FieldSet: ResourceObjectFieldSet,
	FieldSet.Attributes: Encodable,
	FieldSet.Relationships: Encodable
{
	public typealias Attributes = FieldSet.Attributes
	public typealias Relationships = FieldSet.Relationships

	public let type: String = FieldSet.resourceObjectType

	public var id: ID?
	public var attributes: Attributes
	public var relationships: Relationships

	public init(id: ID? = nil, attributes: Attributes, relationships: Relationships) {
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

	enum CodingKeys: String, CodingKey {
		case data
	}

	enum DataCodingKeys: String, CodingKey {
		case type, id, attributes, relationships
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		var nestedContainer = container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)

		try nestedContainer.encode(self.type, forKey: .type)
		try nestedContainer.encodeIfPresent(self.id, forKey: .id)

		if Attributes.self != Unit.self {
			try nestedContainer.encode(self.attributes, forKey: .attributes)
		}

		if Relationships.self != Unit.self {
			try nestedContainer.encode(self.relationships, forKey: .relationships)
		}
	}
}

extension ResourceObjectBody where Attributes == Unit {
	public init(id: ID? = nil, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension ResourceObjectBody where Relationships == Unit {
	public init(id: ID? = nil, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension ResourceObjectBody: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}
