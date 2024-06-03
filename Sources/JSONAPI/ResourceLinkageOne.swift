import Foundation

public struct ResourceLinkageOne: Equatable, Codable {
	public static let empty = ResourceLinkageOne()

	public var data: ResourceIdentifier?

	public init(data: ResourceIdentifier? = nil) {
		self.data = data
	}

	public init<R>(_ resource: R) where R: ResourceIdentifiable {
		self.init(data: ResourceIdentifier(resource))
	}

	public init<R>(_ optionalResource: R?) where R: ResourceIdentifiable {
		self.init(data: optionalResource.map(ResourceIdentifier.init))
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		// explicitly encode nil values
		try container.encode(self.data, forKey: .data)
	}
}
