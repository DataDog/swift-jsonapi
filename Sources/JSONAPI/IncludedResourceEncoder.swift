import Foundation

public final class IncludedResourceEncoder {
  private var container: UnkeyedEncodingContainer
  private var encodedIdentifiers: Set<ResourceIdentifier>

  init(container: UnkeyedEncodingContainer) {
    self.container = container
    self.encodedIdentifiers = []
  }

  public func encode<T>(_ value: T) throws where T: EncodableResource {
    let resourceIdentifier = value.resourceIdentifier

    guard !self.encodedIdentifiers.contains(resourceIdentifier) else {
      return
    }

    try self.container.encode(value)
    encodedIdentifiers.insert(resourceIdentifier)
  }
}
