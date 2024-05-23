import Foundation

public protocol Resource {
	associatedtype ID: Hashable & CustomStringConvertible & Codable

	var type: String { get }
	var id: ID { get }
}

public protocol ResourceType {
	static var resourceType: String { get }
}

public typealias DecodableResource = Decodable & Resource
public typealias EncodableResource = Encodable & Resource
public typealias CodableResource = DecodableResource & EncodableResource
