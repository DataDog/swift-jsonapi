import Foundation

public struct Document<PrimaryData, Meta> {
	public var data: PrimaryData
	public var meta: Meta

	public init(data: PrimaryData, meta: Meta) {
		self.data = data
		self.meta = meta
	}

	public init(data: PrimaryData) where Meta == Unit {
		self.init(data: data, meta: Unit())
	}
}

extension Document: Equatable where PrimaryData: Equatable, Meta: Equatable {
}

extension Document: Decodable where PrimaryData: Decodable, Meta: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Make the included resource decoder available to child decoders
		if let includedResourceDecoderStorage = decoder.userInfo.includedResourceDecoderStorage {
			let identifiers = try container.decodeIfPresent([ResourceIdentifier].self, forKey: .included) ?? []
			let includedResourceDecoder = IncludedResourceDecoder(
				userInfo: decoder.userInfo,
				identifiers: identifiers
			) {
				try container.nestedUnkeyedContainer(forKey: .included)
			}
			includedResourceDecoderStorage.includedResourceDecoder = includedResourceDecoder
		}

		self.data = try container.decode(PrimaryData.self, forKey: .data)

		if let meta = Unit() as? Meta {
			self.meta = meta
		} else {
			self.meta = try container.decode(Meta.self, forKey: .meta)
		}
	}
}

extension Document: Encodable where PrimaryData: Encodable, Meta: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(self.data, forKey: .data)

		if Meta.self != Unit.self {
			try container.encode(self.meta, forKey: .meta)
		}

		var includedContainer = container.nestedUnkeyedContainer(forKey: .included)
		try encoder.includedResourceEncoder?.encodeResources(into: &includedContainer)
	}
}

extension Document {
	fileprivate enum CodingKeys: String, CodingKey {
		case data, meta, included
	}
}
