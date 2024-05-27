import Foundation

public protocol ResourceObjectFieldSet {
	associatedtype Attributes = Unit
	associatedtype Relationships = Unit

	static var resourceObjectType: String { get }
}
