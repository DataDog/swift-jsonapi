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
}

extension Decoder {
	var resourceObjectDecoder: ResourceObjectDecoder? {
		self.userInfo.resourceObjectDecoderStorage?.resourceObjectDecoder
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
}

final class ResourceObjectDecoderStorage {
	var resourceObjectDecoder: ResourceObjectDecoder?
}

extension CodingUserInfoKey {
	fileprivate static let ignoresMissingResources = Self(rawValue: "JSONAPI.ignoresMissingResources")!
	fileprivate static let ignoresUnhandledResourceTypes = Self(rawValue: "JSONAPI.ignoresUnhandledResourceTypes")!
	fileprivate static let resourceObjectDecoderStorage = Self(rawValue: "JSONAPI.resourceObjectDecoderStorage")!
}
