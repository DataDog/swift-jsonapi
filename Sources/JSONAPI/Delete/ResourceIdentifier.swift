import Foundation

public struct ResourceIdentifier: Hashable, Codable {
	public var type: String
	public var id: String

	public init(type: String, id: String) {
		self.type = type
		self.id = id
	}

	public init<T>(_ resource: T) where T: Resource {
		self.init(type: resource.type, id: String(describing: resource.id))
	}
}
