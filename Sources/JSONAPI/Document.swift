import Foundation

public struct Document<Content> {
	public var data: Content

	public init(data: Content) {
		self.data = data
	}
}

extension Document: Equatable where Content: Equatable {
}

extension Document: Decodable where Content: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Make the included resource decoder available to child decoders
		if let includedResourceDecoderStorage = decoder.userInfo.includedResourceDecoderStorage {
			let identifiers = try container.decodeIfPresent([ResourceIdentifier].self, forKey: .included) ?? []
			let includedResourceDecoder = IncludedResourceDecoder(identifiers: identifiers) {
				try container.nestedUnkeyedContainer(forKey: .included)
			}
			includedResourceDecoderStorage.includedResourceDecoder = includedResourceDecoder
		}

		self.data = try container.decode(Content.self, forKey: .data)
	}
}

extension Document: Encodable where Content: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(self.data, forKey: .data)

		var includedContainer = container.nestedUnkeyedContainer(forKey: .included)
		try encoder.includedResourceEncoder?.encodeResources(into: &includedContainer)
	}
}

extension Document {
	fileprivate enum CodingKeys: String, CodingKey {
		case data, included
	}
}
