import Foundation

extension JSONDecoder {
  public var decodesIncludedResources: Bool {
    get {
      userInfo.includedResourceDecoderStorage != nil
    }
    set {
      userInfo.includedResourceDecoderStorage = newValue ? IncludedResourceDecoderStorage() : nil
    }
  }

  public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: DecodableResource {
    self.decodesIncludedResources = true
    return try self.decode(Document<T>.self, from: data).data
  }

  public func decode<T>(
    _ type: T.Type,
    from data: Data
  ) throws -> T where T: Collection, T: Decodable, T.Element: DecodableResource {
    self.decodesIncludedResources = true
    return try self.decode(Document<T>.self, from: data).data
  }
}

extension Decoder {
  public var includedResourceDecoder: IncludedResourceDecoder? {
    userInfo.includedResourceDecoderStorage?.includedResourceDecoder
  }
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
  fileprivate(set) var includedResourceDecoderStorage: IncludedResourceDecoderStorage? {
    get {
      self[IncludedResourceDecoderStorage.key] as? IncludedResourceDecoderStorage
    }
    set {
      self[IncludedResourceDecoderStorage.key] = newValue
    }
  }
}

final class IncludedResourceDecoderStorage {
  fileprivate static let key = CodingUserInfoKey(
    rawValue: "JSONAPI.IncludedResourceDecoderStorage"
  )!

  var includedResourceDecoder: IncludedResourceDecoder?
}
