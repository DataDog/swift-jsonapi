import Foundation
import JSONAPI

// MARK: - Person

@ResourceWrapper(type: "people")
struct Person: Equatable {
	var id: String

	@ResourceAttribute var firstName: String
	@ResourceAttribute var lastName: String
	@ResourceAttribute var twitter: String?
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

@ResourceWrapper(type: "articles")
struct Article: Equatable {
	var id: String

	@ResourceAttribute var title: String
	@ResourceRelationship var author: Person
	@ResourceRelationship var comments: [Comment]
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
