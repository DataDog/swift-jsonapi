import Foundation

public class JSONAPIEncoder: JSONEncoder {
	public override init() {
		super.init()
		self.userInfo.resourceObjectEncoder = ResourceObjectEncoder()
		// TODO: delete this
		self.userInfo.includedResourceEncoder = IncludedResourceEncoder()
	}

	public func encode<R>(_ value: R) throws -> Data where R: ResourceObjectIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}

	public func encode<C>(
		_ value: C
	) throws -> Data where C: Collection & Encodable, C.Element: ResourceObjectIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}

	// TODO: delete this
	public func encode<T>(_ value: T) throws -> Data where T: EncodableResource {
		try self.encode(Document(data: value))
	}

	// TODO: delete this
	public func encode<T>(
		_ value: T
	) throws -> Data where T: Collection, T: Encodable, T.Element: EncodableResource {
		try self.encode(Document(data: value))
	}
}

extension Encoder {
	var resourceObjectEncoder: ResourceObjectEncoder? {
		self.userInfo.resourceObjectEncoder
	}

	// TODO: delete this
	public var includedResourceEncoder: IncludedResourceEncoder? {
		userInfo.includedResourceEncoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate var resourceObjectEncoder: ResourceObjectEncoder? {
		get {
			self[.resourceObjectEncoder] as? ResourceObjectEncoder
		}
		set {
			self[.resourceObjectEncoder] = newValue
		}
	}

	// TODO: delete this
	fileprivate var includedResourceEncoder: IncludedResourceEncoder? {
		get {
			self[IncludedResourceEncoder.key] as? IncludedResourceEncoder
		}
		set {
			self[IncludedResourceEncoder.key] = newValue
		}
	}
}

extension CodingUserInfoKey {
	fileprivate static let resourceObjectEncoder = Self(rawValue: "JSONAPI.resourceObjectEncoder")!
}
