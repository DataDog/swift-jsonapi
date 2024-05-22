import Foundation

public class JSONAPIEncoder: JSONEncoder {
	public override init() {
		super.init()
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
	public var includedResourceEncoder: IncludedResourceEncoder? {
		userInfo.includedResourceEncoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate var includedResourceEncoder: IncludedResourceEncoder? {
		get {
			self[IncludedResourceEncoder.key] as? IncludedResourceEncoder
		}
		set {
			self[IncludedResourceEncoder.key] = newValue
		}
	}
}
