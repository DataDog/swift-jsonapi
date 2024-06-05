import Foundation

@dynamicMemberLookup
public struct RelationshipOptional<R> {
	public var resource: R?

	public init(_ resource: R?) {
		self.resource = resource
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<R, V>) -> V? {
		self.resource?[keyPath: keyPath]
	}
}

extension RelationshipOptional: Equatable where R: Equatable {
}

extension RelationshipOptional: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let rawRelationship = try RawRelationshipOne(from: decoder)

		if let data = rawRelationship.data {
			guard let resourceDecoder = decoder.resourceDecoder else {
				fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
			}

			self.resource = try resourceDecoder.decodeIfPresent(R.self, identifier: data)
		} else {
			self.resource = nil
		}
	}
}

extension RelationshipOptional: Encodable where R: Encodable, R: ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		try RawRelationshipOne(self.resource).encode(to: encoder)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encodeIfPresent(self.resource)
	}
}
