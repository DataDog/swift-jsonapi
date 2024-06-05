import Foundation

public struct RawRelationshipMany: Equatable, Codable {
	public static let empty = RawRelationshipMany()

	@DefaultEmpty public var data: [ResourceIdentifier]

	public init(data: [ResourceIdentifier] = []) {
		self.data = data
	}

	public init<R>(_ resources: [R]) where R: ResourceIdentifiable {
		self.init(data: resources.map(ResourceIdentifier.init))
	}
}
