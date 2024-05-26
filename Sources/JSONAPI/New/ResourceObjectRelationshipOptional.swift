import Foundation

public struct RawResourceObjectRelationshipOptional: Equatable, Codable {
	public var data: ResourceObjectIdentifier?
}

public struct ResourceObjectOptionalRelationship<R> where R: ResourceObjectIdentifiable {
	public var destination: R?
}

extension ResourceObjectOptionalRelationship: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		guard let linkedResourceObjectDecoder = decoder.linkedResourceObjectDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

	}
}
