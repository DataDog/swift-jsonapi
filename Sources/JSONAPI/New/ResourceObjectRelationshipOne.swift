import Foundation

public struct RawResourceObjectRelationshipOne: Equatable, Codable {
	public var data: ResourceObjectIdentifier
}

public struct ResourceObjectRelationshipOne<R> where R: ResourceObjectIdentifiable {
	public var destination: R
}

extension ResourceObjectRelationshipOne: Decodable where R: ResourceObjectDecodable {
	public init(from decoder: any Decoder) throws {
		guard let linkedResourceObjectDecoder = decoder.linkedResourceObjectDecoder else {
			fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
		}

		let rawRelationship = try RawResourceObjectRelationshipOne(from: decoder)
		self.destination = try linkedResourceObjectDecoder.decode(R.self, identifier: rawRelationship.data)
	}
}

extension ResourceObjectRelationshipOne: Encodable where R: Encodable {
	public func encode(to encoder: any Encoder) throws {
		let rawRelationship = RawResourceObjectRelationshipOne(data: .init(self.destination))
		try rawRelationship.encode(to: encoder)

		guard let linkedResourceObjectEncoder = encoder.linkedResourceObjectEncoder else {
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
		}

		linkedResourceObjectEncoder.encode(self.destination)
	}
}

/*
init(from decoder: any Decoder) throws {
	let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
	try container.checkResourceType(Self.self)
	self.id = try container.decode(String.self, forKey: .id)
	let attributesContainer = try container.nestedContainer(keyedBy: ResourceAttributeCodingKeys.self, forKey: .attributes)
	self.title = try attributesContainer.decode(String.self, forKey: .title)
	guard let includedResourceDecoder = decoder.includedResourceDecoder else {
		fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
	}
	let relationshipsContainer = try container.nestedContainer(keyedBy: ResourceRelationshipCodingKeys.self, forKey: .relationships)
	let authorRelationship = try relationshipsContainer.decode(RelationshipToOne.self, forKey: .author)
	self.author = try includedResourceDecoder.decode(Person.self, forRelationship: authorRelationship)
	let commentsRelationship = try relationshipsContainer.decode(RelationshipToMany.self, forKey: .comments)
	self.comments = try includedResourceDecoder.decode([Comment].self, forRelationship: commentsRelationship)
}
func encode(to encoder: any Encoder) throws {
	var container = encoder.container(keyedBy: ResourceCodingKeys.self)
	try container.encode(self.type, forKey: .type)
	try container.encode(self.id, forKey: .id)
	var attributesContainer = container.nestedContainer(keyedBy: ResourceAttributeCodingKeys.self, forKey: .attributes)
	try attributesContainer.encode(self.title, forKey: .title)
	guard let includedResourceEncoder = encoder.includedResourceEncoder else {
		fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
	}
	var relationshipsContainer = container.nestedContainer(keyedBy: ResourceRelationshipCodingKeys.self, forKey: .relationships)
	try relationshipsContainer.encode(RelationshipToOne(resource: self.author), forKey: .author)
	includedResourceEncoder.encode(self.author)
	try relationshipsContainer.encode(RelationshipToMany(resources: self.comments), forKey: .comments)
	includedResourceEncoder.encode(self.comments)
}
*/
