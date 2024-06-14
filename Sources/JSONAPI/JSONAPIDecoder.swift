import Foundation

/// An object that decodes JSON:API documents.
///
/// The example below demonstrates how to decode an array of `Article` values from a
/// [JSON:API](https://jsonapi.org) document. The types involved use the
/// ``ResourceWrapper(type:)`` macro to enable JSON:API decoding.
///
/// ```swift
/// @ResourceWrapper(type: "people")
/// struct Person: Equatable {
///   var id: String
///
///   @ResourceAttribute var firstName: String
///   @ResourceAttribute var lastName: String
///   @ResourceAttribute var twitter: String?
/// }
///
/// @ResourceWrapper(type: "comments")
/// struct Comment: Equatable {
///   var id: String
///
///   @ResourceAttribute var body: String
///   @ResourceRelationship var author: Person?
/// }
///
/// @ResourceWrapper(type: "articles")
/// struct Article: Equatable {
///   var id: String
///
///   @ResourceAttribute var title: String
///   @ResourceRelationship var author: Person
///   @ResourceRelationship var comments: [Comment]
/// }
///
/// let json = """
/// {
///   "data": [
///     {
///       "type": "articles",
///       "id": "1",
///       ...
///     },
///     ...
///   ]
/// }
/// """.data(using: .utf8)!
///
/// let decoder = JSONAPIDecoder()
/// let articles = try decoder.decode([Article].self, from: json)
/// ```
public class JSONAPIDecoder: JSONDecoder {
	/// Indicates whether the decoder should ignore missing included resources when decoding a to-many relationship.
	///
	/// The default value of this property is `false`.
	public var ignoresMissingResources: Bool {
		get { userInfo.ignoresMissingResources }
		set { userInfo.ignoresMissingResources = newValue }
	}

	/// Indicates whether the decoder should ignore unknown resource types when decoding polymorphic relationships.
	///
	/// The default value of this property is `false`.
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
