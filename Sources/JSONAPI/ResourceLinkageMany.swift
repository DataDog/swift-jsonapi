import Foundation

public struct ResourceLinkageMany: Equatable, Codable {
	public var data: [ResourceObjectIdentifier]

	public init(data: [ResourceObjectIdentifier]) {
		self.data = data
	}

	public init<R>(_ resources: [R]) where R: ResourceObjectIdentifiable {
		self.init(data: resources.map(ResourceObjectIdentifier.init))
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.data = try container.decodeIfPresent([ResourceObjectIdentifier].self, forKey: .data) ?? []
	}
}
