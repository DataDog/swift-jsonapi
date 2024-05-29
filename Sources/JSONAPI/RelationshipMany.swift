import Foundation

public struct RelationshipMany<R> {
	private var destination: [R]

	public init(_ destination: [R]) {
		self.destination = destination
	}
}

extension RelationshipMany: RandomAccessCollection {
	public typealias Index = Int
	public typealias Element = R

	public var startIndex: Int {
		self.destination.startIndex
	}

	public var endIndex: Int {
		self.destination.endIndex
	}

	public func index(after i: Int) -> Int {
		self.destination.index(after: i)
	}

	public func index(before i: Int) -> Int {
		self.destination.index(before: i)
	}

	public subscript(position: Int) -> R {
		self.destination[position]
	}
}

extension RelationshipMany: Equatable where R: Equatable {
}

extension RelationshipMany: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let resourceLinkage = try ResourceLinkageMany(from: decoder)

		guard let resourceObjectDecoder = decoder.resourceObjectDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.destination = try resourceObjectDecoder.decode([R].self, identifiers: resourceLinkage.data)
	}
}

extension RelationshipMany: Encodable where R: Encodable & ResourceObjectIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		try ResourceLinkageMany(self.destination).encode(to: encoder)

		guard let resourceObjectEncoder = encoder.resourceObjectEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceObjectEncoder.encode(self.destination)
	}
}
