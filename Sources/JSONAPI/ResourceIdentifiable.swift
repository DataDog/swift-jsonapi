import Foundation

/// A type that can be identified as a JSON:API resource.
public protocol ResourceIdentifiable {
	associatedtype ID: Hashable & CustomStringConvertible

	var type: String { get }
	var id: ID { get }
}

extension ResourceIdentifiable where Self: ResourceDefinitionProviding {
	public var type: String {
		Definition.resourceType
	}
}
