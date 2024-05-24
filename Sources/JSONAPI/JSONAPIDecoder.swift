import Foundation

public class JSONAPIDecoder: JSONDecoder {
	public var ignoresMissingResources: Bool {
		get { userInfo.ignoresMissingResources }
		set { userInfo.ignoresMissingResources = newValue }
	}

	public var ignoresUnhandledResourceTypes: Bool {
		get { userInfo.ignoresUnhandledResourceTypes }
		set { userInfo.ignoresUnhandledResourceTypes = newValue }
	}

	public override init() {
		super.init()
		self.userInfo.includedResourceDecoderStorage = IncludedResourceDecoderStorage()
	}

	public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: DecodableResource {
		try self.decode(Document<T, Unit>.self, from: data).data
	}

	public func decode<T>(
		_ type: T.Type,
		from data: Data
	) throws -> T where T: RangeReplaceableCollection, T: Decodable, T.Element: DecodableResource {
		try self.decode(Document<T?, Unit>.self, from: data).data ?? T()
	}

	public func decode<T, Meta>(
		_ type: Document<T, Meta>.Type,
		from data: Data
	) throws -> Document<T, Meta>
	where T: RangeReplaceableCollection, T: Decodable, T.Element: DecodableResource, Meta: Decodable {
		let document = try self.decode(Document<T?, Meta>.self, from: data)
		return Document(data: document.data ?? T(), meta: document.meta)
	}
}

extension Decoder {
	public var includedResourceDecoder: IncludedResourceDecoder? {
		userInfo.includedResourceDecoderStorage?.includedResourceDecoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate(set) var ignoresMissingResources: Bool {
		get {
			(self[.ignoresMissingResources] as? Bool) ?? false
		}
		set {
			self[.ignoresMissingResources] = newValue
		}
	}

	fileprivate(set) var ignoresUnhandledResourceTypes: Bool {
		get {
			(self[.ignoresUnhandledResourceTypes] as? Bool) ?? false
		}
		set {
			self[.ignoresUnhandledResourceTypes] = newValue
		}
	}

	fileprivate(set) var includedResourceDecoderStorage: IncludedResourceDecoderStorage? {
		get {
			self[.includedResourceDecoderStorage] as? IncludedResourceDecoderStorage
		}
		set {
			self[.includedResourceDecoderStorage] = newValue
		}
	}
}

final class IncludedResourceDecoderStorage {
	var includedResourceDecoder: IncludedResourceDecoder?
}

extension CodingUserInfoKey {
	fileprivate static let ignoresMissingResources = Self(rawValue: "JSONAPI.ignoresMissingResources")!
	fileprivate static let ignoresUnhandledResourceTypes = Self(rawValue: "JSONAPI.ignoresUnhandledResourceTypes")!
	fileprivate static let includedResourceDecoderStorage = Self(rawValue: "JSONAPI.IncludedResourceDecoderStorage")!
}
