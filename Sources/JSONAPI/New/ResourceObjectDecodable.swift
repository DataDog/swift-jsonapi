import Foundation

public protocol ResourceObjectDecodable: ResourceObjectIdentifiable, Decodable {
}

extension ResourceObjectDecodable
where
	Self: ResourceObjectFieldProviding,
	Self.Attributes: Decodable,
	Self.Relationships: Decodable
{
	public init(from decoder: any Decoder) throws {
		let resourceObject = try ResourceObject<Self>(from: decoder)
		self.init(
			id: resourceObject.id,
			attributes: resourceObject.attributes,
			relationships: resourceObject.relationships
		)
	}
}
