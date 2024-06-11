import Foundation

public struct ResourceBody<ID, Definition>: Encodable
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
		func isEmpty<T>(_ value: T) -> Bool {
			let mirror = Mirror(reflecting: value)

			for child in mirror.children {
				let childMirror = Mirror(reflecting: child.value)

				guard childMirror.displayStyle == .optional else {
					return false
				}

				guard childMirror.children.isEmpty else {
					return false
				}
			}

			return true
		}

		var container = encoder.container(keyedBy: CodingKeys.self)
		var nestedContainer = container.nestedContainer(keyedBy: ResourceCodingKeys.self, forKey: .data)

		try nestedContainer.encode(self.type, forKey: .type)
		try nestedContainer.encodeIfPresent(self.id, forKey: .id)

		if Attributes.self != Unit.self, let attributes, !isEmpty(attributes) {
			try nestedContainer.encode(attributes, forKey: .attributes)
		}

		if Relationships.self != Unit.self, let relationships, !isEmpty(relationships) {
			try nestedContainer.encode(relationships, forKey: .relationships)
		}
	}
}

extension ResourceBody: ResourceLinkageProviding {
	public static func resourceIdentifier(_ id: ID) -> ResourceIdentifier {
		ResourceIdentifier(type: Definition.resourceType, id: String(describing: id))
	}
}

extension ResourceBody where Attributes == Unit {
	public init(id: ID? = nil, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension ResourceBody where Relationships == Unit {
	public init(id: ID? = nil, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension ResourceBody: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}
