import Foundation

extension JSONEncoder {
  public var encodesIncludedResources: Bool {
    get {
      userInfo.includedResourceEncoderStorage != nil
    }
    set {
      userInfo.includedResourceEncoderStorage =
        newValue ? IncludedResourceEncoderStorage() : nil
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
    userInfo.includedResourceEncoderStorage?.includedResourceEncoder
  }
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
  var includedResourceEncoderStorage: IncludedResourceEncoderStorage? {
    get {
      self[IncludedResourceEncoderStorage.key] as? IncludedResourceEncoderStorage
    }
    set {
      self[IncludedResourceEncoderStorage.key] = newValue
    }
  }
}

final class IncludedResourceEncoderStorage {
  fileprivate static let key = CodingUserInfoKey(
    rawValue: "JSONAPI.IncludedResourceEncoderStorage"
  )!

  var includedResourceEncoder: IncludedResourceEncoder?
}
