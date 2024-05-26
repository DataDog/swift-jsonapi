import Foundation

public struct RawResourceObjectRelationshipMany: Equatable, Codable {
	public var data: [ResourceObjectIdentifier]

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.data = try container.decodeIfPresent([ResourceObjectIdentifier].self, forKey: .data) ?? []
	}
}
