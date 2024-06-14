// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A JSON:API to-many relationship that includes the related resources.
///
/// Use `InlineRelationshipMany` when providing a ``ResourceDefinition`` to define a to-many relationship that embeds
/// the related resources in the JSON:API document `included` section.
public struct InlineRelationshipMany<Destination> {
	/// The related resources.
	public var resources: [Destination]

	public init(_ resources: [Destination]) {
		self.resources = resources
	}
}

extension InlineRelationshipMany: RandomAccessCollection {
	public typealias Index = Int
	public typealias Element = Destination

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

	public subscript(position: Int) -> Destination {
		self.resources[position]
	}
}

extension InlineRelationshipMany: Equatable where Destination: Equatable {
}

extension InlineRelationshipMany: Decodable where Destination: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let data = try container.decodeIfPresent([ResourceIdentifier].self, forKey: .data) ?? []

		guard let resourceDecoder = decoder.resourceDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		self.resources = try resourceDecoder.decode([Destination].self, identifiers: data)
	}
}

extension InlineRelationshipMany: Encodable where Destination: Encodable & ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let data = self.resources.map(ResourceIdentifier.init)

		try container.encode(data, forKey: .data)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encode(self.resources)
	}
}

extension InlineRelationshipMany {
	fileprivate enum CodingKeys: String, CodingKey {
		case data
	}
}
