import Foundation

/// A JSON:API optional to-one relationship that includes the related resource.
///
/// Use `InlineRelationshipOptional` when providing a ``ResourceDefinition`` to define an optional to-one relationship
/// that embeds the related resource in the JSON:API document `included` section.
@dynamicMemberLookup
public struct InlineRelationshipOptional<Destination> {
	/// The related resource.
	public var resource: Destination?

	public init(_ resource: Destination?) {
		self.resource = resource
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Destination, V>) -> V? {
		self.resource?[keyPath: keyPath]
	}
}

extension InlineRelationshipOptional: Equatable where Destination: Equatable {
}

extension InlineRelationshipOptional: Decodable where Destination: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		if let data = try container.decodeIfPresent(ResourceIdentifier.self, forKey: .data) {
			guard let resourceDecoder = decoder.resourceDecoder else {
				fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
			}

			self.resource = try resourceDecoder.decodeIfPresent(Destination.self, identifier: data)
		} else {
			self.resource = nil
		}
	}
}

extension InlineRelationshipOptional: Encodable where Destination: Encodable, Destination: ResourceIdentifiable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let data = resource.map(ResourceIdentifier.init)

		// explicitly encode nil values
		try container.encode(data, forKey: .data)

		guard let resourceEncoder = encoder.resourceEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		resourceEncoder.encodeIfPresent(self.resource)
	}
}

extension InlineRelationshipOptional {
	fileprivate enum CodingKeys: String, CodingKey {
		case data
	}
}
