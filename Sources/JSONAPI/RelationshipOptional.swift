import Foundation

@dynamicMemberLookup
public struct RelationshipOptional<R> {
	public var destination: R?

	public init(_ destination: R?) {
		self.destination = destination
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<R, V>) -> V? {
		self.destination?[keyPath: keyPath]
	}
}

extension RelationshipOptional: Equatable where R: Equatable {
}

extension RelationshipOptional: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let resourceLinkage = try ResourceLinkageOne(from: decoder)

		if let data = resourceLinkage.data {
			guard let resourceObjectDecoder = decoder.resourceObjectDecoder else {
				fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
			}

			self.destination = try resourceObjectDecoder.decodeIfPresent(R.self, identifier: data)
		} else {
			self.destination = nil
		}
	}
}

extension RelationshipOptional: Encodable where R: Encodable, R: ResourceObjectIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		try ResourceLinkageOne(self.destination).encode(to: encoder)

		guard let resourceObjectEncoder = encoder.resourceObjectEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceObjectEncoder.encodeIfPresent(self.destination)
	}
}
