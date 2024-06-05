import Foundation

public struct ResourceUpdate<ID, Definition>: Encodable
where
	ID: Hashable & Encodable,
	Definition: ResourceDefinition,
	Definition.Attributes: Encodable,
	Definition.Relationships: Encodable
{
	public typealias Attributes = Definition.Attributes
	public typealias Relationships = Definition.Relationships

	public let type: String = Definition.resourceType

	public var id: ID?
	public var attributes: Attributes?
	public var relationships: Relationships?

	public init(id: ID? = nil, attributes: Attributes? = nil, relationships: Relationships? = nil) {
		self.id = id
		self.attributes = attributes
		self.relationships = relationships
	}

	private enum CodingKeys: String, CodingKey {
		case data
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		var nestedContainer = container.nestedContainer(keyedBy: ResourceCodingKeys.self, forKey: .data)

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
