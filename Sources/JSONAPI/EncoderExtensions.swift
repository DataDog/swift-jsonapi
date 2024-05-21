import Foundation

extension JSONEncoder {
	public var encodesIncludedResources: Bool {
		get {
			userInfo.includedResourceEncoder != nil
		}
		set {
			userInfo.includedResourceEncoder = newValue ? IncludedResourceEncoder() : nil
		}
	}

	public func encode<T>(_ value: T) throws -> Data where T: EncodableResource {
		self.encodesIncludedResources = true
		return try self.encode(Document(data: value))
	}

	public func encode<T>(
		_ value: T
	) throws -> Data where T: Collection, T: Encodable, T.Element: EncodableResource {
		self.encodesIncludedResources = true
		return try self.encode(Document(data: value))
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
