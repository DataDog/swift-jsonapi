import Foundation
import JSONAPI

struct PersonID: Hashable {
	var rawValue: String

	init(rawValue: String) {
		self.rawValue = rawValue
	}
}

extension PersonID: RawRepresentable {}
extension PersonID: Codable {}

extension PersonID: CustomStringConvertible {
	var description: String {
		rawValue.description
	}
}

extension PersonID: ExpressibleByStringLiteral {
	init(stringLiteral value: String.StringLiteralType) {
		self.init(rawValue: String(stringLiteral: value))
	}
}

@CodableResource(type: "people")
struct Person: Equatable {
	// Exercise a tagged type instead of a string
	var id: PersonID

	@ResourceAttribute
	var firstName: String

	@ResourceAttribute
	var lastName: String

	@ResourceAttribute
	var twitter: String?
}

@CodableResource(type: "comments")
struct Comment: Equatable {
	var id: String

	@ResourceAttribute
	var body: String

	@ResourceRelationship
	var author: Person?
}

@CodableResource(type: "articles")
struct Article: Equatable {
	var id: String

	@ResourceAttribute
	var title: String

	@ResourceRelationship
	var author: Person

	@ResourceRelationship
	var comments: [Comment]
}

@CodableResource(type: "schedules")
struct Schedule: Equatable {
	var id: String

	@ResourceAttribute
	var name: String

	@ResourceAttribute
	var tags: [String]
}

@CodableResource(type: "images")
struct Image: Equatable {
	var id: String

	@ResourceAttribute
	var url: URL

	@ResourceAttribute
	var width: Int

	@ResourceAttribute
	var height: Int
}

@CodableResource(type: "audios")
struct Audio: Equatable {
	var id: String

	@ResourceAttribute
	var url: URL

	@ResourceAttribute
	var title: String
}

@CodableResourceUnion
enum Attachment: Equatable {
	case image(Image)
	case audio(Audio)
}

@CodableResource(type: "messages")
struct Message: Equatable {
	var id: String

	@ResourceAttribute
	var text: String

	@ResourceRelationship
	var attachments: [Attachment]
}

@CodableResource(type: "single_attachment_messages")
struct SingleAttachmentMessage: Equatable {
	var id: String

	@ResourceAttribute
	var text: String

	@ResourceRelationship
	var attachment: Attachment?
}
