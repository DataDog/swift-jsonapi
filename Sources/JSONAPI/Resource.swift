import Foundation

public protocol Resource {
  associatedtype ID: Hashable & CustomStringConvertible & Codable

  static var type: String { get }

  var id: ID { get }
}

public typealias DecodableResource = Decodable & Resource
public typealias EncodableResource = Encodable & Resource
public typealias CodableResource = DecodableResource & EncodableResource

extension Resource {
  public var resourceIdentifier: ResourceIdentifier {
    .init(type: Self.type, id: String(describing: self.id))
  }
}
