import Foundation

public struct ResourceObjectIdentifier: Hashable, Codable {
	public var type: String
	public var id: String

	public init(type: String, id: String) {
		self.type = type
		self.id = id
	}

	public init<R>(_ resourceObject: R) where R: ResourceObjectIdentifiable {
		self.init(type: resourceObject.type, id: resourceObject.id.description)
	}
}
