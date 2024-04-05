import Foundation

public struct RelationshipToOne: Equatable, Codable {
  public var data: ResourceIdentifier

  public init(data: ResourceIdentifier) {
    self.data = data
  }

  public init<T>(resource: T) where T: Resource {
    self.init(data: resource.resourceIdentifier)
  }

  public init?<T>(resource: T?) where T: Resource {
    guard let resource else {
      return nil
    }
    self.init(data: resource.resourceIdentifier)
  }
}
