import Foundation

@dynamicMemberLookup
public struct InlineRelationshipOne<Destination> {
	public var resource: Destination

	public init(_ resource: Destination) {
		self.resource = resource
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Destination, V>) -> V {
		self.resource[keyPath: keyPath]
	}
}

extension InlineRelationshipOne: Equatable where Destination: Equatable {
}

extension InlineRelationshipOne: Decodable where Destination: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let data = try container.decode(ResourceIdentifier.self, forKey: .data)

		guard let resourceDecoder = decoder.resourceDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.resource = try resourceDecoder.decode(Destination.self, identifier: data)
	}
}

extension InlineRelationshipOne: Encodable where Destination: Encodable & ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let data = ResourceIdentifier(resource)

		try container.encode(data, forKey: .data)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encode(self.resource)
	}
}

extension InlineRelationshipOne {
	fileprivate enum CodingKeys: String, CodingKey {
		case data
	}
}
