import Foundation
import JSONAPI

// MARK: - Person

struct Person: Equatable {
	var id: String

	@ResourceAttribute public var firstName: String
	@ResourceAttribute var lastName: String
	@ResourceAttribute var twitter: String?
}

extension Person {
	struct FieldSet: ResourceFieldSet {
		struct Attributes: Equatable, Codable {
			// coding keys when needed!
			var firstName: String
			var lastName: String
			var twitter: String?
		}

		static let resourceType = "people"
	}

	struct UpdateFieldSet: ResourceFieldSet {
		struct Attributes: Equatable, Encodable {
			// coding keys when needed!
			var firstName: String?
			var lastName: String?
			var twitter: String?
		}

		static let resourceType = FieldSet.resourceType
	}

	typealias Primitive = Resource<String, FieldSet>
	typealias Update = ResourceUpdate<String, UpdateFieldSet>
}

extension Person: ResourceIdentifiable {
	var type: String {
		FieldSet.resourceType
	}
}

extension Person: Codable {
	init(from decoder: any Decoder) throws {
		let primitive = try Primitive(from: decoder)
		self.id = primitive.id
		self.firstName = primitive.firstName
		self.lastName = primitive.lastName
		self.twitter = primitive.twitter
	}

	func encode(to encoder: any Encoder) throws {
		try Primitive(
			id: self.id,
			attributes: .init(firstName: self.firstName, lastName: self.lastName, twitter: self.twitter)
		).encode(to: encoder)
	}
}

// MARK: - Comment

@ResourceWrapper(type: "comments")
struct Comment: Equatable {
	var id: String

	@ResourceAttribute var body: String
	@ResourceRelationship var author: Person?
}

extension Comment: ResourceIdentifiable {
	var type: String {
		FieldSet.resourceType
	}
}

extension Comment: Codable {
	init(from decoder: any Decoder) throws {
		let primitive = try Primitive(from: decoder)
		self.id = primitive.id
		self.body = primitive.body
		self.author = primitive.author.resource
	}

	func encode(to encoder: any Encoder) throws {
		try Primitive(
			id: self.id,
			attributes: .init(body: self.body),
			relationships: .init(author: RelationshipOptional(self.author))
		).encode(to: encoder)
	}
}

// MARK: - Article

struct Article: Equatable {
	var id: String

	var title: String
	var author: Person
	var comments: [Comment]
}

extension Article {
	struct FieldSet: ResourceFieldSet {
		struct Attributes: Equatable, Codable {
			var title: String
		}
		struct Relationships: Equatable, Codable {
			var author: RelationshipOne<Person>
			var comments: RelationshipMany<Comment>
		}
		static let resourceType = "articles"
	}

	struct UpdateFieldSet: ResourceFieldSet {
		struct Attributes: Equatable, Encodable {
			var title: String?
		}
		struct Relationships: Equatable, Encodable {
			var author: ResourceLinkageOne?
			var comments: ResourceLinkageMany?
		}
		static let resourceType = FieldSet.resourceType
	}

	typealias Primitive = Resource<String, FieldSet>
	typealias Update = ResourceUpdate<String, UpdateFieldSet>
}

extension Article: ResourceIdentifiable {
	var type: String {
		FieldSet.resourceType
	}
}

extension Article: Codable {
	init(from decoder: any Decoder) throws {
		let primitive = try Primitive(from: decoder)
		self.id = primitive.id
		self.title = primitive.title
		self.author = primitive.author.resource
		self.comments = primitive.comments.resources
	}

	func encode(to encoder: any Encoder) throws {
		try Primitive(
			id: self.id,
			attributes: .init(title: self.title),
			relationships: .init(author: RelationshipOne(self.author), comments: RelationshipMany(self.comments))
		).encode(to: encoder)
	}
}
