import Foundation

public struct ResourceLinkageOne: Equatable, Codable {
	public var data: ResourceObjectIdentifier?

	public init(data: ResourceObjectIdentifier? = nil) {
		self.data = data
	}

	public init<R>(_ resource: R) where R: ResourceObjectIdentifiable {
		self.init(data: ResourceObjectIdentifier(resource))
	}

	public init<R>(_ optionalResource: R?) where R: ResourceObjectIdentifiable {
		self.init(data: optionalResource.map(ResourceObjectIdentifier.init))
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		// explicitly encode nil values
		if let data {
			try container.encode(data, forKey: .data)
		} else {
			try container.encodeNil(forKey: .data)
		}
	}
}
