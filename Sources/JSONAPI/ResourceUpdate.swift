import Foundation

public struct ResourceUpdate<ID, FieldSet>: Encodable
where
	ID: Hashable & Encodable,
	FieldSet: ResourceFieldSet,
	FieldSet.Attributes: Encodable,
	FieldSet.Relationships: Encodable
{
	public typealias Attributes = FieldSet.Attributes
	public typealias Relationships = FieldSet.Relationships

	public let type: String = FieldSet.resourceType

	public var id: ID?
	public var attributes: Attributes?
	public var relationships: Relationships?

	public init(id: ID? = nil, attributes: Attributes? = nil, relationships: Relationships? = nil) {
		self.id = id
		self.attributes = attributes
		self.relationships = relationships
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
			try nestedContainer.encodeIfPresent(self.attributes, forKey: .attributes)
		}

		if Relationships.self != Unit.self {
			try nestedContainer.encodeIfPresent(self.relationships, forKey: .relationships)
		}
	}
}

extension ResourceUpdate where Attributes == Unit {
	public init(id: ID? = nil, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension ResourceUpdate where Relationships == Unit {
	public init(id: ID? = nil, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension ResourceUpdate: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}
