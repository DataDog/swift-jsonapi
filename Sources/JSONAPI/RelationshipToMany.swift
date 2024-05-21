import Foundation

public struct RelationshipToMany: Equatable, Codable {
	public var data: [ResourceIdentifier]

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.data = try container.decodeIfPresent([ResourceIdentifier].self, forKey: .data) ?? []
	}

	public init(data: [ResourceIdentifier]) {
		self.data = data
	}

	public init<T>(resources: T) where T: Sequence, T.Element: Resource {
		self.init(data: resources.map(ResourceIdentifier.init))
	}

	public init?<T>(resources: T?) where T: Sequence, T.Element: Resource {
		guard let resources else {
			return nil
		}
		self.init(data: resources.map(ResourceIdentifier.init))
	}
}
