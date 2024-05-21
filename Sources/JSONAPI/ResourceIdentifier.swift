import Foundation

public struct ResourceIdentifier: Hashable, Codable {
	public var type: String
	public var id: String

	public init(type: String, id: String) {
		self.type = type
		self.id = id
	}
}
