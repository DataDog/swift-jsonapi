import Foundation

public struct RelationshipToMany: Equatable, Codable {
  public var data: [ResourceIdentifier]

  public init(data: [ResourceIdentifier]) {
    self.data = data
  }

  public init<T>(resources: T) where T: Sequence, T.Element: Resource {
    self.init(data: resources.map(\.resourceIdentifier))
  }
}
