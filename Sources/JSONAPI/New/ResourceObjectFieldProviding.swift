import Foundation

public protocol ResourceObjectFieldProviding: ResourceObjectIdentifiable {
	associatedtype Attributes
	associatedtype Relationships

	init(id: ID, attributes: Attributes, relationships: Relationships)
}
