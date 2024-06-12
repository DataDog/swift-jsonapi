import JSONAPIMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class ResourceWrapperMacroTests: XCTestCase {
	override func invokeTest() {
		withMacroTesting(
			macros: [
				ResourceWrapperMacro.self,
				ResourceAttributeMacro.self,
				ResourceRelationshipMacro.self,
			]
		) {
			super.invokeTest()
		}
	}

	func testResourceWrapperRequiresStruct() {
		assertMacro {
			"""
			@ResourceWrapper(type: "people")
			class Person {
				var id: UUID
			}
			"""
		} diagnostics: {
			"""
			@ResourceWrapper(type: "people")
			┬───────────────────────────────
			╰─ 🛑 '@ResourceWrapper' can only be applied to struct types
			class Person {
				var id: UUID
			}
			"""
		}
	}

	func testResourceWrapperRequiresType() {
		assertMacro {
			"""
			@ResourceWrapper(type: "")
			struct Person {
				var id: UUID
			}
			"""
		} diagnostics: {
			"""
			@ResourceWrapper(type: "")
			┬─────────────────────────
			╰─ 🛑 '@ResourceWrapper' requires a non-empty string literal containing the type of the resource
			struct Person {
				var id: UUID
			}
			"""
		}
	}

	func testResourceWrapperRequiresIdProperty() {
		assertMacro {
			"""
			@ResourceWrapper(type: "people")
			struct Person {
			}
			"""
		} diagnostics: {
			"""
			@ResourceWrapper(type: "people")
			╰─ 🛑 '@ResourceWrapper' requires a valid 'id' property.
			struct Person {
			}
			"""
		}
	}

	func testResourceWrapper() {
		assertMacro {
			"""
			@ResourceWrapper(type: "articles")
			struct Article {
				var id: UUID

				@ResourceAttribute var title: String
				@ResourceRelationship var author: Person
				@ResourceRelationship var comments: [Comment]
			}
			"""
		} expansion: {
			"""
			struct Article {
				var id: UUID

				var title: String
				var author: Person
				var comments: [Comment]
			}

			extension Article: JSONAPI.ResourceDefinitionProviding {
				struct Definition: JSONAPI.ResourceDefinition {
					struct Attributes: Codable {
						var title: String
					}
					struct Relationships: Codable {
						var author: JSONAPI.InlineRelationshipOne<Person>
						var comments: JSONAPI.InlineRelationshipMany<Comment>
					}
					static let resourceType = "articles"
				}
				struct BodyDefinition: JSONAPI.ResourceDefinition {
					struct Attributes: Codable {
						var title: String?
					}
					struct Relationships: Codable {
						var author: JSONAPI.RelationshipOne<Person>?
						var comments: JSONAPI.RelationshipMany<Comment>?
					}
					static let resourceType = Definition.resourceType
				}
				typealias Wrapped = JSONAPI.Resource<UUID, Definition>
				typealias Body = JSONAPI.ResourceBody<UUID, BodyDefinition>
			}

			extension Article: JSONAPI.ResourceIdentifiable {
			}

			extension Article: JSONAPI.ResourceLinkageProviding {
				typealias ID = UUID
			}

			extension Article: Codable {
				init(from decoder: any Decoder) throws {
					let wrapped = try Wrapped(from: decoder)
					self.id = wrapped.id
					self.title = wrapped.title
					self.author = wrapped.author.resource
					self.comments = wrapped.comments.resources
				}
				func encode(to encoder: any Encoder) throws {
					let attributes = Wrapped.Attributes(title: self.title)
					let relationships = Wrapped.Relationships(author: .init(self.author), comments: .init(self.comments))
					let wrapped = Wrapped(id: self.id, attributes: attributes, relationships: relationships)
					try wrapped.encode(to: encoder)
				}
			}

			extension Article {
				static func createBody(id: UUID? = nil, title: String? = nil, author: JSONAPI.RelationshipOne<Person>? = nil, comments: JSONAPI.RelationshipMany<Comment>? = nil) -> Article.Body {
					let attributes = Body.Attributes(title: title)
					let relationships = Body.Relationships(author: author, comments: comments)
					return Body(id: id, attributes: attributes, relationships: relationships)
				}
				static func updateBody(id: UUID, title: String? = nil, author: JSONAPI.RelationshipOne<Person>? = nil, comments: JSONAPI.RelationshipMany<Comment>? = nil) -> Article.Body {
					let attributes = Body.Attributes(title: title)
					let relationships = Body.Relationships(author: author, comments: comments)
					return Body(id: id, attributes: attributes, relationships: relationships)
				}
			}
			"""
		}
	}

	func testResourceWrapperCodingKeys() {
		assertMacro {
			"""
			@ResourceWrapper(type: "people")
			struct Person: Equatable {
				var id: String

				@ResourceAttribute(key: "first_name") var firstName: String
				@ResourceAttribute var lastName: String
				@ResourceRelationship(key: "related_person") var related: Person?
			}
			"""
		} expansion: {
			"""
			struct Person: Equatable {
				var id: String

				var firstName: String
				var lastName: String
				var related: Person?
			}

			extension Person: JSONAPI.ResourceDefinitionProviding {
				struct Definition: JSONAPI.ResourceDefinition {
					struct Attributes: Equatable, Codable {
						private enum CodingKeys: String, CodingKey {
						    case firstName = "first_name"
						    case lastName
						}
						var firstName: String
						var lastName: String
					}
					struct Relationships: Equatable, Codable {
						private enum CodingKeys: String, CodingKey {
						    case related = "related_person"
						}
						var related: JSONAPI.InlineRelationshipOptional<Person>
					}
					static let resourceType = "people"
				}
				struct BodyDefinition: JSONAPI.ResourceDefinition {
					struct Attributes: Equatable, Codable {
						private enum CodingKeys: String, CodingKey {
						    case firstName = "first_name"
						    case lastName
						}
						var firstName: String?
						var lastName: String?
					}
					struct Relationships: Equatable, Codable {
						private enum CodingKeys: String, CodingKey {
						    case related = "related_person"
						}
						var related: JSONAPI.RelationshipOne<Person>?
					}
					static let resourceType = Definition.resourceType
				}
				typealias Wrapped = JSONAPI.Resource<String, Definition>
				typealias Body = JSONAPI.ResourceBody<String, BodyDefinition>
			}

			extension Person: JSONAPI.ResourceIdentifiable {
			}

			extension Person: JSONAPI.ResourceLinkageProviding {
				typealias ID = String
			}

			extension Person: Codable {
				init(from decoder: any Decoder) throws {
					let wrapped = try Wrapped(from: decoder)
					self.id = wrapped.id
					self.firstName = wrapped.firstName
					self.lastName = wrapped.lastName
					self.related = wrapped.related.resource
				}
				func encode(to encoder: any Encoder) throws {
					let attributes = Wrapped.Attributes(firstName: self.firstName, lastName: self.lastName)
					let relationships = Wrapped.Relationships(related: .init(self.related))
					let wrapped = Wrapped(id: self.id, attributes: attributes, relationships: relationships)
					try wrapped.encode(to: encoder)
				}
			}

			extension Person {
				static func createBody(id: String? = nil, firstName: String? = nil, lastName: String? = nil, related: JSONAPI.RelationshipOne<Person>? = nil) -> Person.Body {
					let attributes = Body.Attributes(firstName: firstName, lastName: lastName)
					let relationships = Body.Relationships(related: related)
					return Body(id: id, attributes: attributes, relationships: relationships)
				}
				static func updateBody(id: String, firstName: String? = nil, lastName: String? = nil, related: JSONAPI.RelationshipOne<Person>? = nil) -> Person.Body {
					let attributes = Body.Attributes(firstName: firstName, lastName: lastName)
					let relationships = Body.Relationships(related: related)
					return Body(id: id, attributes: attributes, relationships: relationships)
				}
			}
			"""
		}
	}

	func testResourceWrapperAccessControl() {
		assertMacro {
			"""
			@ResourceWrapper(type: "people")
			public struct Person: Equatable {
				public var id: String

				@ResourceAttribute public var firstName: String
				@ResourceAttribute var lastName: String
				@ResourceRelationship public var related: Person?
			}
			"""
		} expansion: {
			"""
			public struct Person: Equatable {
				public var id: String

				public var firstName: String
				var lastName: String
				public var related: Person?
			}

			extension Person: JSONAPI.ResourceDefinitionProviding {
				public struct Definition: JSONAPI.ResourceDefinition {
					public struct Attributes: Equatable, Codable {
						public var firstName: String
						var lastName: String
					}
					public struct Relationships: Equatable, Codable {
						public var related: JSONAPI.InlineRelationshipOptional<Person>
					}
					public static let resourceType = "people"
				}
				public struct BodyDefinition: JSONAPI.ResourceDefinition {
					public struct Attributes: Equatable, Codable {
						public var firstName: String?
						var lastName: String?
					}
					public struct Relationships: Equatable, Codable {
						public var related: JSONAPI.RelationshipOne<Person>?
					}
					public static let resourceType = Definition.resourceType
				}
				public typealias Wrapped = JSONAPI.Resource<String, Definition>
				public typealias Body = JSONAPI.ResourceBody<String, BodyDefinition>
			}

			extension Person: JSONAPI.ResourceIdentifiable {
			}

			extension Person: JSONAPI.ResourceLinkageProviding {
				public typealias ID = String
			}

			extension Person: Codable {
				public init(from decoder: any Decoder) throws {
					let wrapped = try Wrapped(from: decoder)
					self.id = wrapped.id
					self.firstName = wrapped.firstName
					self.lastName = wrapped.lastName
					self.related = wrapped.related.resource
				}
				public func encode(to encoder: any Encoder) throws {
					let attributes = Wrapped.Attributes(firstName: self.firstName, lastName: self.lastName)
					let relationships = Wrapped.Relationships(related: .init(self.related))
					let wrapped = Wrapped(id: self.id, attributes: attributes, relationships: relationships)
					try wrapped.encode(to: encoder)
				}
			}

			extension Person {
				public static func createBody(id: String? = nil, firstName: String? = nil, lastName: String? = nil, related: JSONAPI.RelationshipOne<Person>? = nil) -> Person.Body {
					let attributes = Body.Attributes(firstName: firstName, lastName: lastName)
					let relationships = Body.Relationships(related: related)
					return Body(id: id, attributes: attributes, relationships: relationships)
				}
				public static func updateBody(id: String, firstName: String? = nil, lastName: String? = nil, related: JSONAPI.RelationshipOne<Person>? = nil) -> Person.Body {
					let attributes = Body.Attributes(firstName: firstName, lastName: lastName)
					let relationships = Body.Relationships(related: related)
					return Body(id: id, attributes: attributes, relationships: relationships)
				}
			}
			"""
		}
	}

	func testAvailability() {
		assertMacro {
			"""
			@available(iOS, unavailable)
			@ResourceWrapper(type: "people")
			public struct Person: Equatable {
				public var id: String
			}
			"""
		} expansion: {
			"""
			@available(iOS, unavailable)
			public struct Person: Equatable {
				public var id: String
			}

			@available(iOS, unavailable)
			extension Person: JSONAPI.ResourceDefinitionProviding {
				public struct Definition: JSONAPI.ResourceDefinition {
					public static let resourceType = "people"
				}
				public struct BodyDefinition: JSONAPI.ResourceDefinition {
					public static let resourceType = Definition.resourceType
				}
				public typealias Wrapped = JSONAPI.Resource<String, Definition>
				public typealias Body = JSONAPI.ResourceBody<String, BodyDefinition>
			}

			@available(iOS, unavailable)
			extension Person: JSONAPI.ResourceIdentifiable {
			}

			@available(iOS, unavailable)
			extension Person: JSONAPI.ResourceLinkageProviding {
				public typealias ID = String
			}

			@available(iOS, unavailable)
			extension Person: Codable {
				public init(from decoder: any Decoder) throws {
					let wrapped = try Wrapped(from: decoder)
					self.id = wrapped.id
				}
				public func encode(to encoder: any Encoder) throws {
					let wrapped = Wrapped(id: self.id)
					try wrapped.encode(to: encoder)
				}
			}

			@available(iOS, unavailable)
			extension Person {
				public static func createBody(id: String? = nil) -> Person.Body {
					return Body(id: id)
				}
				public static func updateBody(id: String) -> Person.Body {
					return Body(id: id)
				}
			}
			"""
		}
	}

	func testResourceWrapperArrayAttribute() {
		assertMacro {
			"""
			@ResourceWrapper(type: "schedules")
			struct Schedule: Equatable {
				var id: UUID

				@ResourceAttribute
				var name: String

				@ResourceAttribute
				var tags: [String]
			}
			"""
		} expansion: {
			"""
			struct Schedule: Equatable {
				var id: UUID
				var name: String
				var tags: [String]
			}

			extension Schedule: JSONAPI.ResourceDefinitionProviding {
				struct Definition: JSONAPI.ResourceDefinition {
					struct Attributes: Equatable, Codable {
						var name: String
						@DefaultEmpty
							var tags: [String]
					}
					static let resourceType = "schedules"
				}
				struct BodyDefinition: JSONAPI.ResourceDefinition {
					struct Attributes: Equatable, Codable {
						var name: String?

						var tags: [String]?
					}
					static let resourceType = Definition.resourceType
				}
				typealias Wrapped = JSONAPI.Resource<UUID, Definition>
				typealias Body = JSONAPI.ResourceBody<UUID, BodyDefinition>
			}

			extension Schedule: JSONAPI.ResourceIdentifiable {
			}

			extension Schedule: JSONAPI.ResourceLinkageProviding {
				typealias ID = UUID
			}

			extension Schedule: Codable {
				init(from decoder: any Decoder) throws {
					let wrapped = try Wrapped(from: decoder)
					self.id = wrapped.id
					self.name = wrapped.name
					self.tags = wrapped.tags
				}
				func encode(to encoder: any Encoder) throws {
					let attributes = Wrapped.Attributes(name: self.name, tags: self.tags)
					let wrapped = Wrapped(id: self.id, attributes: attributes)
					try wrapped.encode(to: encoder)
				}
			}

			extension Schedule {
				static func createBody(id: UUID? = nil, name: String? = nil, tags: [String]? = nil) -> Schedule.Body {
					let attributes = Body.Attributes(name: name, tags: tags)
					return Body(id: id, attributes: attributes)
				}
				static func updateBody(id: UUID, name: String? = nil, tags: [String]? = nil) -> Schedule.Body {
					let attributes = Body.Attributes(name: name, tags: tags)
					return Body(id: id, attributes: attributes)
				}
			}
			"""
		}
	}
}
