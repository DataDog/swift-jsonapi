import Foundation

public struct PrimitiveRelationshipOne: Equatable, Codable {
	public var data: ResourceObjectIdentifier

	public init(data: ResourceObjectIdentifier) {
		self.data = data
	}
}

public struct RelationshipOne<R> {
	public var destination: R

	public init(_ destination: R) {
		self.destination = destination
	}
}

extension RelationshipOne: Equatable where R: Equatable {
}

extension RelationshipOne: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let rawRelationship = try PrimitiveRelationshipOne(from: decoder)

		guard let resourceObjectDecoder = decoder.resourceObjectDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.destination = try resourceObjectDecoder.decode(R.self, identifier: rawRelationship.data)
	}
}

extension RelationshipOne: Encodable where R: Encodable & ResourceObjectIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		let rawRelationship = PrimitiveRelationshipOne(data: .init(self.destination))
		try rawRelationship.encode(to: encoder)

		guard let resourceObjectEncoder = encoder.resourceObjectEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceObjectEncoder.encode(self.destination)
	}
}
