import Foundation

public protocol Resource {
  var type: String { get }
  var id: String { get }
}

public typealias DecodableResource = Decodable & Resource
public typealias EncodableResource = Encodable & Resource
public typealias CodableResource = DecodableResource & EncodableResource

extension Resource {
  public var resourceIdentifier: ResourceIdentifier {
    .init(type: self.type, id: self.id)
  }
}
