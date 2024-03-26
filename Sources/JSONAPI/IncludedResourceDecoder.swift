import Foundation

public final class IncludedResourceDecoder {
  private let container: () throws -> any UnkeyedDecodingContainer
  private let indexByIdentifier: [ResourceIdentifier: Int]

  init(
    identifiers: [ResourceIdentifier],
    container: @escaping () throws -> any UnkeyedDecodingContainer
  ) {
    self.indexByIdentifier = Dictionary(
      zip(identifiers, identifiers.indices),
      uniquingKeysWith: { first, _ in first }
    )
    self.container = container
  }

  public func decode<T>(
    _ type: T.Type,
    forIdentifier identifier: ResourceIdentifier
  ) throws -> T where T: DecodableResource {
    guard let resource = try self.decodeIfPresent(type, forIdentifier: identifier) else {
      throw DecodingError.valueNotFound(
        type,
        .init(
          codingPath: (try? self.container())?.codingPath ?? [],
          debugDescription:
            "Could not find resource of type '\(identifier.type)' with id '\(identifier.id)'."
        )
      )
    }

    return resource
  }

  public func decodeIfPresent<T>(
    _ type: T.Type,
    forIdentifier identifier: ResourceIdentifier
  ) throws -> T? where T: DecodableResource {
    guard let index = self.indexByIdentifier[identifier] else {
      return nil
    }

    return try self.decode(T.self, at: index)
  }

  public func decode<T>(
    _ type: [T].Type,
    forIdentifiers identifiers: [ResourceIdentifier]
  ) throws -> [T] where T: DecodableResource {
    try identifiers.map {
      try self.decode(T.self, forIdentifier: $0)
    }
  }

  private func decode<T>(_ type: T.Type, at index: Int) throws -> T where T: DecodableResource {
    var container = try self.container()

    precondition(index < container.count!)

    while container.currentIndex < index {
      _ = try container.decode(ResourceIdentifier.self)
    }

    return try container.decode(T.self)
  }
}
