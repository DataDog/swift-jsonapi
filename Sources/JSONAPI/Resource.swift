import Foundation

public protocol Resource {
  static var type: String { get }
  var id: String { get }
}

public typealias DecodableResource = Decodable & Resource
public typealias EncodableResource = Encodable & Resource
public typealias CodableResource = DecodableResource & EncodableResource

extension Resource {
  public var resourceIdentifier: ResourceIdentifier {
    .init(type: Self.type, id: self.id)
  }
}
