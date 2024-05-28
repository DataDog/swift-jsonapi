import Foundation

public struct RelationshipOneRef<ID, FieldSet>: Encodable
where
	ID: CustomStringConvertible,
	FieldSet: ResourceObjectFieldSet
{
	public let id: ID
	
	public init(id: ID) {
		self.id = id
	}
	
	public func encode(to encoder: any Encoder) throws {
		let primitive = PrimitiveRelationshipOne(
			data: ResourceObjectIdentifier(
				type: FieldSet.resourceObjectType,
				id: self.id.description
			)
		)
		try primitive.encode(to: encoder)
	}
}

extension RelationshipOneRef: Equatable where ID: Equatable {
}
