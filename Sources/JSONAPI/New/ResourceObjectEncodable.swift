import Foundation

public protocol ResourceObjectEncodable: ResourceObjectIdentifiable, Encodable {
}

extension ResourceObjectEncodable
where
	Self: ResourceObjectFieldProviding,
	Self.Attributes: Encodable,
	Self.Relationships: Encodable
{
	public func encode(to encoder: any Encoder) throws {
		// TODO: implement
		//		let resourceObject = ResourceObject<Self>()
	}
}
