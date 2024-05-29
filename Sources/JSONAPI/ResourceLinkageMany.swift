import Foundation

public struct ResourceLinkageMany: Equatable, Codable {
	public static let empty = ResourceLinkageMany()

	public var data: [ResourceIdentifier]

	public init(data: [ResourceIdentifier] = []) {
		self.data = data
	}

	public init<R>(_ resources: [R]) where R: ResourceIdentifiable {
		self.init(data: resources.map(ResourceIdentifier.init))
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.data = try container.decodeIfPresent([ResourceIdentifier].self, forKey: .data) ?? []
	}
}
