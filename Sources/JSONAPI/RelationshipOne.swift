import Foundation

@dynamicMemberLookup
public struct RelationshipOne<R> {
	public var destination: R

	public init(_ destination: R) {
		self.destination = destination
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<R, V>) -> V {
		self.destination[keyPath: keyPath]
	}
}

extension RelationshipOne: Equatable where R: Equatable {
}

extension RelationshipOne: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let resourceLinkage = try ResourceLinkageOne(from: decoder)

		guard let data = resourceLinkage.data else {
			throw DecodingError.valueNotFound(
				Self.self,
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Could not find a resource identifier for this relationship."
				)
			)
		}

		guard let resourceDecoder = decoder.resourceDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.destination = try resourceDecoder.decode(R.self, identifier: data)
	}
}

extension RelationshipOne: Encodable where R: Encodable & ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		try ResourceLinkageOne(self.destination).encode(to: encoder)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encode(self.destination)
	}
}
