import Foundation

public class JSONAPIEncoder: JSONEncoder {
	public override init() {
		super.init()
		self.userInfo.resourceEncoder = ResourceEncoder()
	}

	public func encode<R>(_ value: R) throws -> Data where R: ResourceIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}

	public func encode<C>(
		_ value: C
	) throws -> Data where C: Collection & Encodable, C.Element: ResourceIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}
}

extension Encoder {
	var resourceEncoder: ResourceEncoder? {
		self.userInfo.resourceEncoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate var resourceEncoder: ResourceEncoder? {
		get {
			self[.resourceEncoder] as? ResourceEncoder
		}
		set {
			self[.resourceEncoder] = newValue
		}
	}
}

extension CodingUserInfoKey {
	fileprivate static let resourceEncoder = Self(rawValue: "JSONAPI.resourceEncoder")!
}
