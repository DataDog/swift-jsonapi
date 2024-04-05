import Foundation

public struct OptionalRelationshipToOne: Equatable, Codable {
  public var data: ResourceIdentifier?

  public init(data: ResourceIdentifier? = nil) {
    self.data = data
  }
}
