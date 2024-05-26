import Foundation

@dynamicMemberLookup
public struct ResourceObject<R> where R: ResourceObjectFieldProviding {
	public typealias ID = R.ID
	public typealias Attributes = R.Attributes
	public typealias Relationships = R.Relationships

	public let type: String
	public var id: ID
	public var attributes: Attributes
	public var relationships: Relationships

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<Attributes, V>) -> V {
		get { self.attributes[keyPath: keyPath] }
		set { self.attributes[keyPath: keyPath] = newValue }
	}

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<Relationships, V>) -> V {
		get { self.relationships[keyPath: keyPath] }
		set { self.relationships[keyPath: keyPath] = newValue }
	}
}

extension ResourceObject: Equatable where Attributes: Equatable, Relationships: Equatable {
}

extension ResourceObject: Decodable where Attributes: Decodable, Relationships: Decodable {
}

extension ResourceObject: Encodable where Attributes: Encodable, Relationships: Encodable {
}
