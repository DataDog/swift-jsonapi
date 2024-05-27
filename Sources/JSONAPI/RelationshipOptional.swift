import Foundation

public struct PrimitiveRelationshipOptional: Equatable, Codable {
	public var data: ResourceObjectIdentifier?

	public init(data: ResourceObjectIdentifier?) {
		self.data = data
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		// explicitly encode nil values
		if let data {
			try container.encode(data, forKey: .data)
		} else {
			try container.encodeNil(forKey: .data)
		}
	}
}

public struct RelationshipOptional<R> {
	public var destination: R?

	public init(_ destination: R?) {
		self.destination = destination
	}
}

extension RelationshipOptional: Equatable where R: Equatable {
}

extension RelationshipOptional: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let rawRelationship = try PrimitiveRelationshipOptional(from: decoder)

		guard let resourceObjectDecoder = decoder.resourceObjectDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.destination = try resourceObjectDecoder.decodeIfPresent(R.self, identifier: rawRelationship.data)
	}
}

extension RelationshipOptional: Encodable where R: Encodable, R: ResourceObjectIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		let rawRelationship = PrimitiveRelationshipOptional(
			data: self.destination.map(ResourceObjectIdentifier.init)
		)
		try rawRelationship.encode(to: encoder)

		guard let resourceObjectEncoder = encoder.resourceObjectEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceObjectEncoder.encodeIfPresent(self.destination)
	}
}
