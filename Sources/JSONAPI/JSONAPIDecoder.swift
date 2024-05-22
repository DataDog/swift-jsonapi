import Foundation

public class JSONAPIDecoder: JSONDecoder {
	public override init() {
		super.init()
		self.userInfo.includedResourceDecoderStorage = IncludedResourceDecoderStorage()
	}

	public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: DecodableResource {
		try self.decode(Document<T>.self, from: data).data
	}

	public func decode<T>(
		_ type: T.Type,
		from data: Data
	) throws -> T where T: RangeReplaceableCollection, T: Decodable, T.Element: DecodableResource {
		try self.decode(Document<T?>.self, from: data).data ?? T()
	}
}

extension Decoder {
	public var includedResourceDecoder: IncludedResourceDecoder? {
		userInfo.includedResourceDecoderStorage?.includedResourceDecoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate(set) var includedResourceDecoderStorage: IncludedResourceDecoderStorage? {
		get {
			self[IncludedResourceDecoderStorage.key] as? IncludedResourceDecoderStorage
		}
		set {
			self[IncludedResourceDecoderStorage.key] = newValue
		}
	}
}

final class IncludedResourceDecoderStorage {
	fileprivate static let key = CodingUserInfoKey(
		rawValue: "JSONAPI.IncludedResourceDecoderStorage"
	)!

	var includedResourceDecoder: IncludedResourceDecoder?
}
