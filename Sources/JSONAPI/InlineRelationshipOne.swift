// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A JSON:API to-one relationship that includes the related resource.
///
/// Use `InlineRelationshipOne` when providing a ``ResourceDefinition`` to define a to-one relationship that embeds
/// the related resource in the JSON:API document `included` section.
@dynamicMemberLookup
public struct InlineRelationshipOne<Destination> {
	/// The related resource.
	public var resource: Destination

	public init(_ resource: Destination) {
		self.resource = resource
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Destination, V>) -> V {
		self.resource[keyPath: keyPath]
	}
}

extension InlineRelationshipOne: Equatable where Destination: Equatable {
}

extension InlineRelationshipOne: Decodable where Destination: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let data = try container.decode(ResourceIdentifier.self, forKey: .data)

		guard let resourceDecoder = decoder.resourceDecoder else {
			throw JSONAPIDecodingError.resourceDecoderNotFound
		}

		self.resource = try resourceDecoder.decode(Destination.self, identifier: data)
	}
}

extension InlineRelationshipOne: Encodable where Destination: Encodable & ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let data = ResourceIdentifier(resource)

		try container.encode(data, forKey: .data)

		guard let resourceEncoder = encoder.resourceEncoder else {
			throw JSONAPIEncodingError.resourceEncoderNotFound
		}

		resourceEncoder.encode(self.resource)
	}
}

extension InlineRelationshipOne {
	fileprivate enum CodingKeys: String, CodingKey {
		case data
	}
}
