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

		self.userInfo.resourceObjectDecoderStorage = ResourceObjectDecoderStorage()
		// TODO: delete this
		self.userInfo.includedResourceDecoderStorage = IncludedResourceDecoderStorage()
	}

	public func decode<R>(_: R.Type, from data: Data) throws -> R where R: ResourceObjectIdentifiable & Decodable {
		try self.decode(CompoundDocument<R, Unit>.self, from: data).data
	}

	public func decode<C>(
		_: C.Type,
		from data: Data
	) throws -> C where C: RangeReplaceableCollection, C: Decodable, C.Element: ResourceObjectIdentifiable & Decodable {
		try self.decode(CompoundDocument<C?, Unit>.self, from: data).data ?? C()
	}

	public func decode<C, M>(
		_: CompoundDocument<C, M>.Type,
		from data: Data
	) throws -> CompoundDocument<C, M>
	where
		C: RangeReplaceableCollection, C: Decodable, C.Element: ResourceObjectIdentifiable & Decodable, M: Decodable
	{
		let document = try self.decode(CompoundDocument<C?, M>.self, from: data)
		return CompoundDocument(data: document.data ?? C(), meta: document.meta)
	}

	// TODO: delete this
	public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: DecodableResource {
		try self.decode(Document<T, Unit>.self, from: data).data
	}

	// TODO: delete this
	public func decode<T>(
		_ type: T.Type,
		from data: Data
	) throws -> T where T: RangeReplaceableCollection, T: Decodable, T.Element: DecodableResource {
		try self.decode(Document<T?, Unit>.self, from: data).data ?? T()
	}

	// TODO: delete this
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
	var resourceObjectDecoder: ResourceObjectDecoder? {
		self.userInfo.resourceObjectDecoderStorage?.resourceObjectDecoder
	}

	// TODO: delete this
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

	fileprivate(set) var resourceObjectDecoderStorage: ResourceObjectDecoderStorage? {
		get {
			self[.resourceObjectDecoderStorage] as? ResourceObjectDecoderStorage
		}
		set {
			self[.resourceObjectDecoderStorage] = newValue
		}
	}

	// TODO: delete this
	fileprivate(set) var includedResourceDecoderStorage: IncludedResourceDecoderStorage? {
		get {
			self[.includedResourceDecoderStorage] as? IncludedResourceDecoderStorage
		}
		set {
			self[.includedResourceDecoderStorage] = newValue
		}
	}
}

final class ResourceObjectDecoderStorage {
	var resourceObjectDecoder: ResourceObjectDecoder?
}

// TODO: delete this
final class IncludedResourceDecoderStorage {
	var includedResourceDecoder: IncludedResourceDecoder?
}

extension CodingUserInfoKey {
	fileprivate static let ignoresMissingResources = Self(rawValue: "JSONAPI.ignoresMissingResources")!
	fileprivate static let ignoresUnhandledResourceTypes = Self(rawValue: "JSONAPI.ignoresUnhandledResourceTypes")!
	fileprivate static let resourceObjectDecoderStorage = Self(rawValue: "JSONAPI.resourceObjectDecoderStorage")!
	// TODO: delete this
	fileprivate static let includedResourceDecoderStorage = Self(rawValue: "JSONAPI.IncludedResourceDecoderStorage")!
}
