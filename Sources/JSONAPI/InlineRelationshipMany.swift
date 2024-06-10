import Foundation

public struct InlineRelationshipMany<R> {
	public var resources: [R]

	public init(_ resources: [R]) {
		self.resources = resources
	}
}

extension InlineRelationshipMany: RandomAccessCollection {
	public typealias Index = Int
	public typealias Element = R

	public var startIndex: Int {
		self.resources.startIndex
	}

	public var endIndex: Int {
		self.resources.endIndex
	}

	public func index(after i: Int) -> Int {
		self.resources.index(after: i)
	}

	public func index(before i: Int) -> Int {
		self.resources.index(before: i)
	}

	public subscript(position: Int) -> R {
		self.resources[position]
	}
}

extension InlineRelationshipMany: Equatable where R: Equatable {
}

extension InlineRelationshipMany: Decodable where R: Decodable {
	public init(from decoder: any Decoder) throws {
		let rawRelationship = try RawRelationshipMany(from: decoder)

		guard let resourceDecoder = decoder.resourceDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.resources = try resourceDecoder.decode([R].self, identifiers: rawRelationship.data)
	}
}

extension InlineRelationshipMany: Encodable where R: Encodable & ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		try RawRelationshipMany(self.resources).encode(to: encoder)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encode(self.resources)
	}
}
