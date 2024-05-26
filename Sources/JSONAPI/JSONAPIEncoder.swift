import Foundation

public class JSONAPIEncoder: JSONEncoder {
	public override init() {
		super.init()
		self.userInfo.linkedResourceObjectEncoder = LinkedResourceObjectEncoder()
		// TODO: delete this
		self.userInfo.includedResourceEncoder = IncludedResourceEncoder()
	}

	public func encode<T>(_ value: T) throws -> Data where T: EncodableResource {
		try self.encode(Document(data: value))
	}

	public func encode<T>(
		_ value: T
	) throws -> Data where T: Collection, T: Encodable, T.Element: EncodableResource {
		try self.encode(Document(data: value))
	}
}

extension Encoder {
	var linkedResourceObjectEncoder: LinkedResourceObjectEncoder? {
		self.userInfo.linkedResourceObjectEncoder
	}

	// TODO: delete this
	public var includedResourceEncoder: IncludedResourceEncoder? {
		userInfo.includedResourceEncoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate var linkedResourceObjectEncoder: LinkedResourceObjectEncoder? {
		get {
			self[.linkedResourceObjectEncoder] as? LinkedResourceObjectEncoder
		}
		set {
			self[.linkedResourceObjectEncoder] = newValue
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
	fileprivate static let linkedResourceObjectEncoder = Self(rawValue: "JSONAPI.linkedResourceObjectEncoder")!
}
