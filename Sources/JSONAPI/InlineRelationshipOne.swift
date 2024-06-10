import Foundation

@dynamicMemberLookup
public struct InlineRelationshipOne<R> {
	public var resource: R

	public init(_ resource: R) {
		self.resource = resource
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<R, V>) -> V {
		self.resource[keyPath: keyPath]
	}
}

extension InlineRelationshipOne: Equatable where R: Equatable {
}

extension InlineRelationshipOne: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let rawRelationship = try RawRelationshipOne(from: decoder)

		guard let data = rawRelationship.data else {
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

		self.resource = try resourceDecoder.decode(R.self, identifier: data)
	}
}

extension InlineRelationshipOne: Encodable where R: Encodable & ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		try RawRelationshipOne(self.resource).encode(to: encoder)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encode(self.resource)
	}
}
