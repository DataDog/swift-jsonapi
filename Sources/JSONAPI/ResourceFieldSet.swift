import Foundation

public protocol ResourceFieldSet {
	associatedtype Attributes = Unit
	associatedtype Relationships = Unit

	static var resourceType: String { get }
}
