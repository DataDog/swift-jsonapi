import Foundation

public struct RelationshipOne<Destination: ResourceLinkageProviding>: Equatable, Codable {
	public static var null: RelationshipOne {
		RelationshipOne(data: nil)
	}

	public var data: ResourceIdentifier?

	public init(id: Destination.ID) {
		self.init(data: Destination.resourceIdentifier(id))
	}

	init(data: ResourceIdentifier?) {
		self.data = data
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		// explicitly encode nil values
		try container.encode(self.data, forKey: .data)
	}
}

extension RelationshipOne: ExpressibleByUnicodeScalarLiteral where Destination.ID: ExpressibleByUnicodeScalarLiteral {
	public typealias UnicodeScalarLiteralType = Destination.ID.UnicodeScalarLiteralType

	public init(unicodeScalarLiteral: UnicodeScalarLiteralType) {
		self.init(id: Destination.ID(unicodeScalarLiteral: unicodeScalarLiteral))
	}
}

extension RelationshipOne: ExpressibleByExtendedGraphemeClusterLiteral
where
	Destination.ID: ExpressibleByExtendedGraphemeClusterLiteral
{
	public typealias ExtendedGraphemeClusterLiteralType = Destination.ID.ExtendedGraphemeClusterLiteralType

	public init(extendedGraphemeClusterLiteral: ExtendedGraphemeClusterLiteralType) {
		self.init(id: Destination.ID(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
	}
}

extension RelationshipOne: ExpressibleByStringLiteral where Destination.ID: ExpressibleByStringLiteral {
	public typealias StringLiteralType = Destination.ID.StringLiteralType

	public init(stringLiteral: StringLiteralType) {
		self.init(id: Destination.ID(stringLiteral: stringLiteral))
	}
}
