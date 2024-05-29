import Foundation

public class JSONAPIEncoder: JSONEncoder {
	public override init() {
		super.init()
		self.userInfo.resourceObjectEncoder = ResourceObjectEncoder()
	}

	public func encode<R>(_ value: R) throws -> Data where R: ResourceObjectIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}

	public func encode<C>(
		_ value: C
	) throws -> Data where C: Collection & Encodable, C.Element: ResourceObjectIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}
}

extension Encoder {
	var resourceObjectEncoder: ResourceObjectEncoder? {
		self.userInfo.resourceObjectEncoder
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
}

extension CodingUserInfoKey {
	fileprivate static let resourceObjectEncoder = Self(rawValue: "JSONAPI.resourceObjectEncoder")!
}
