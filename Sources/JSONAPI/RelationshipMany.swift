import Foundation

public struct PrimitiveRelationshipMany: Equatable, Codable {
	public var data: [ResourceObjectIdentifier]

	public init(data: [ResourceObjectIdentifier]) {
		self.data = data
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.data = try container.decodeIfPresent([ResourceObjectIdentifier].self, forKey: .data) ?? []
	}
}

public struct RelationshipMany<R> {
	public var destination: [R]

	public init(_ destination: [R]) {
		self.destination = destination
	}
}

extension RelationshipMany: Equatable where R: Equatable {
}

extension RelationshipMany: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let rawRelationship = try PrimitiveRelationshipMany(from: decoder)

		guard let resourceObjectDecoder = decoder.resourceObjectDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.destination = try resourceObjectDecoder.decode([R].self, identifiers: rawRelationship.data)
	}
}

extension RelationshipMany: Encodable where R: Encodable & ResourceObjectIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		let rawRelationship = PrimitiveRelationshipMany(data: destination.map(ResourceObjectIdentifier.init))
		try rawRelationship.encode(to: encoder)

		guard let resourceObjectEncoder = encoder.resourceObjectEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceObjectEncoder.encode(destination)
	}
}
