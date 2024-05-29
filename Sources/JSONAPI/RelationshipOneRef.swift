import Foundation

public struct RelationshipOneRef<ID, FieldSet>: Encodable
where
	ID: CustomStringConvertible,
	FieldSet: ResourceObjectFieldSet
{
	public let id: ID?

	public init(id: ID?) {
		self.id = id
	}

	public func encode(to encoder: any Encoder) throws {
		try ResourceLinkageOne(
			data: self.id.map {
				ResourceObjectIdentifier(
					type: FieldSet.resourceObjectType,
					id: $0.description
				)
			}
		).encode(to: encoder)
	}
}

extension RelationshipOneRef: Equatable where ID: Equatable {
}
