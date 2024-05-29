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

		self.userInfo.resourceDecoderStorage = ResourceDecoderStorage()
	}

	public func decode<R>(_: R.Type, from data: Data) throws -> R where R: ResourceIdentifiable & Decodable {
		try self.decode(CompoundDocument<R, Unit>.self, from: data).data
	}

	public func decode<C>(
		_: C.Type,
		from data: Data
	) throws -> C where C: RangeReplaceableCollection, C: Decodable, C.Element: ResourceIdentifiable & Decodable {
		try self.decode(CompoundDocument<C?, Unit>.self, from: data).data ?? C()
	}

	public func decode<C, M>(
		_: CompoundDocument<C, M>.Type,
		from data: Data
	) throws -> CompoundDocument<C, M>
	where
		C: RangeReplaceableCollection, C: Decodable, C.Element: ResourceIdentifiable & Decodable, M: Decodable
	{
		let document = try self.decode(CompoundDocument<C?, M>.self, from: data)
		return CompoundDocument(data: document.data ?? C(), meta: document.meta)
	}
}

extension Decoder {
	var resourceDecoder: ResourceDecoder? {
		self.userInfo.resourceDecoderStorage?.resourceDecoder
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

	fileprivate(set) var resourceDecoderStorage: ResourceDecoderStorage? {
		get {
			self[.resourceDecoderStorage] as? ResourceDecoderStorage
		}
		set {
			self[.resourceDecoderStorage] = newValue
		}
	}
}

final class ResourceDecoderStorage {
	var resourceDecoder: ResourceDecoder?
}

extension CodingUserInfoKey {
	fileprivate static let ignoresMissingResources = Self(rawValue: "JSONAPI.ignoresMissingResources")!
	fileprivate static let ignoresUnhandledResourceTypes = Self(rawValue: "JSONAPI.ignoresUnhandledResourceTypes")!
	fileprivate static let resourceDecoderStorage = Self(rawValue: "JSONAPI.resourceDecoderStorage")!
}
