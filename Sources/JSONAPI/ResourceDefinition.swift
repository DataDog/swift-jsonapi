import Foundation

public protocol ResourceDefinition {
	associatedtype Attributes = Unit
	associatedtype Relationships = Unit

	static var resourceType: String { get }
}
