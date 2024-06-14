import Foundation

/// A unique identifier for a JSON:API resource.
public struct ResourceIdentifier: Hashable, Codable {
	public var type: String
	public var id: String

	public init(type: String, id: String) {
		self.type = type
		self.id = id
	}

	public init<R>(_ resource: R) where R: ResourceIdentifiable {
		self.init(type: resource.type, id: resource.id.description)
	}
}
