import JSONAPIMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class CodableResourceMacroTests: XCTestCase {
	override func invokeTest() {
		withMacroTesting(
			// isRecording: true,
			macros: [
				CodableResourceMacro.self,
				ResourceAttributeMacro.self,
				ResourceRelationshipMacro.self,
			]
		) {
			super.invokeTest()
		}
	}

	func testAttributes() {
		assertMacro {
			"""
			@CodableResource(type: "people")
			struct Person {
			  var id: String
			  
			  @ResourceAttribute
			  var firstName: String

			  @ResourceAttribute(key: "last_name")
			  var lastName: String

			  @ResourceAttribute
			  var birthday: Date?

			  @ResourceAttribute
			  var tags: [String]
			}
			"""
		} expansion: {
			"""
			struct Person {
			  var id: String
			  
			  var firstName: String
			  var lastName: String
			  var birthday: Date?
			  var tags: [String]

			  let type = Self.resourceType
			}

			extension Person: JSONAPI.ResourceType {
			  static let resourceType = "people"
			}

			extension Person: JSONAPI.CodableResource {
			  private enum ResourceAttributeCodingKeys: String, CodingKey {
			    case firstName
			    case lastName = "last_name"
			    case birthday
			    case tags
			  }

			  init(from decoder: any Decoder) throws {
			    let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			    try container.checkResourceType(Self.self)
			    self.id = try container.decode(String.self, forKey: .id)
			    let attributesContainer = try container.nestedContainer(keyedBy: ResourceAttributeCodingKeys.self, forKey: .attributes)
			    self.firstName = try attributesContainer.decode(String.self, forKey: .firstName)
			    self.lastName = try attributesContainer.decode(String.self, forKey: .lastName)
			    self.birthday = try attributesContainer.decodeIfPresent(Date.self, forKey: .birthday)
			    self.tags = try attributesContainer.decodeIfPresent([String].self, forKey: .tags) ?? []
			  }
			  func encode(to encoder: any Encoder) throws {
			    var container = encoder.container(keyedBy: ResourceCodingKeys.self)
			    try container.encode(self.type, forKey: .type)
			    try container.encode(self.id, forKey: .id)
			    var attributesContainer = container.nestedContainer(keyedBy: ResourceAttributeCodingKeys.self, forKey: .attributes)
			    try attributesContainer.encode(self.firstName, forKey: .firstName)
			    try attributesContainer.encode(self.lastName, forKey: .lastName)
			    try attributesContainer.encodeIfPresent(self.birthday, forKey: .birthday)
			    try attributesContainer.encode(self.tags, forKey: .tags)
			  }
			}
			"""
		}
	}

	func testRelationships() {
		assertMacro {
			"""
			@CodableResource(type: "articles")
			struct Article {
			  @ResourceRelationship
			  var author: Person

			  @ResourceRelationship
			  var coauthor: Person?

			  @ResourceRelationship
			  var comments: [Comment]

			  @ResourceRelationship(key: "related_articles")
			  var related: [Article]?
			}
			"""
		} expansion: {
			"""
			struct Article {
			  var author: Person
			  var coauthor: Person?
			  var comments: [Comment]
			  var related: [Article]?

			  let type = Self.resourceType

			  var id: String
			}

			extension Article: JSONAPI.ResourceType {
			  static let resourceType = "articles"
			}

			extension Article: JSONAPI.CodableResource {
			  private enum ResourceRelationshipCodingKeys: String, CodingKey {
			    case author
			    case coauthor
			    case comments
			    case related = "related_articles"
			  }
			  init(from decoder: any Decoder) throws {
			    let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			    try container.checkResourceType(Self.self)
			    self.id = try container.decode(String.self, forKey: .id)
			    guard let includedResourceDecoder = decoder.includedResourceDecoder else {
			      fatalError("You must use a 'JSONAPIDecoder' instance to decode a JSON:API response.")
			    }
			    let relationshipsContainer = try container.nestedContainer(keyedBy: ResourceRelationshipCodingKeys.self, forKey: .relationships)
			    let authorRelationship = try relationshipsContainer.decode(RelationshipToOne.self, forKey: .author)
			    self.author = try includedResourceDecoder.decode(Person.self, forRelationship: authorRelationship)
			    let coauthorRelationship = try relationshipsContainer.decodeIfPresent(OptionalRelationshipToOne.self, forKey: .coauthor)
			    self.coauthor = try includedResourceDecoder.decodeIfPresent(Person.self, forRelationship: coauthorRelationship)
			    let commentsRelationship = try relationshipsContainer.decode(RelationshipToMany.self, forKey: .comments)
			    self.comments = try includedResourceDecoder.decode([Comment].self, forRelationship: commentsRelationship)
			    let relatedRelationship = try relationshipsContainer.decodeIfPresent(RelationshipToMany.self, forKey: .related)
			    self.related = try includedResourceDecoder.decodeIfPresent([Article].self, forRelationship: relatedRelationship)
			  }
			  func encode(to encoder: any Encoder) throws {
			    var container = encoder.container(keyedBy: ResourceCodingKeys.self)
			    try container.encode(self.type, forKey: .type)
			    try container.encode(self.id, forKey: .id)
			    guard let includedResourceEncoder = encoder.includedResourceEncoder else {
			      fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")
			    }
			    var relationshipsContainer = container.nestedContainer(keyedBy: ResourceRelationshipCodingKeys.self, forKey: .relationships)
			    try relationshipsContainer.encode(RelationshipToOne(resource: self.author), forKey: .author)
			    includedResourceEncoder.encode(self.author)
			    try relationshipsContainer.encodeIfPresent(RelationshipToOne(resource: self.coauthor), forKey: .coauthor)
			    includedResourceEncoder.encodeIfPresent(self.coauthor)
			    try relationshipsContainer.encode(RelationshipToMany(resources: self.comments), forKey: .comments)
			    includedResourceEncoder.encode(self.comments)
			    try relationshipsContainer.encodeIfPresent(RelationshipToMany(resources: self.related), forKey: .related)
			    includedResourceEncoder.encodeIfPresent(self.related)
			  }
			}
			"""
		}
	}

	func testAccessControl() {
		assertMacro {
			"""
			@CodableResource(type: "people")
			public struct Person {
			}
			"""
		} expansion: {
			"""
			public struct Person {

			    public let type = Self.resourceType

			    public var id: String
			}

			extension Person: JSONAPI.ResourceType {
			    public  static let resourceType = "people"
			}

			extension Person: JSONAPI.CodableResource {


			    public init(from decoder: any Decoder) throws {
			        let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			        try container.checkResourceType(Self.self)
			        self.id = try container.decode(String.self, forKey: .id)
			    }

			    public func encode(to encoder: any Encoder) throws {
			        var container = encoder.container(keyedBy: ResourceCodingKeys.self)
			        try container.encode(self.type, forKey: .type)
			        try container.encode(self.id, forKey: .id)
			    }
			}
			"""
		}
	}

	func testRedundancy() {
		assertMacro {
			"""
			@CodableResource(type: "people")
			struct Person {
			  typealias Id = Tagged<Person, String>

			  var id: Id
			}
			"""
		} expansion: {
			"""
			struct Person {
			  typealias Id = Tagged<Person, String>

			  var id: Id

			  let type = Self.resourceType
			}

			extension Person: JSONAPI.ResourceType {
			  static let resourceType = "people"
			}

			extension Person: JSONAPI.CodableResource {

			  init(from decoder: any Decoder) throws {
			    let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			    try container.checkResourceType(Self.self)
			    self.id = try container.decode(Id.self, forKey: .id)
			  }
			  func encode(to encoder: any Encoder) throws {
			    var container = encoder.container(keyedBy: ResourceCodingKeys.self)
			    try container.encode(self.type, forKey: .type)
			    try container.encode(self.id, forKey: .id)
			  }
			}
			"""
		}
	}

	func testAvailability() {
		assertMacro {
			"""
			@available(macOS, unavailable)
			@CodableResource(type: "people")
			struct Person {
			}
			"""
		} expansion: {
			"""
			@available(macOS, unavailable)
			struct Person {

			    let type = Self.resourceType

			    var id: String
			}

			@available(macOS, unavailable)
			extension Person: JSONAPI.ResourceType {
			    static let resourceType = "people"
			}

			@available(macOS, unavailable)
			extension Person: JSONAPI.CodableResource {

			    init(from decoder: any Decoder) throws {
			        let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			        try container.checkResourceType(Self.self)
			        self.id = try container.decode(String.self, forKey: .id)
			    }
			    func encode(to encoder: any Encoder) throws {
			        var container = encoder.container(keyedBy: ResourceCodingKeys.self)
			        try container.encode(self.type, forKey: .type)
			        try container.encode(self.id, forKey: .id)
			    }
			}
			"""
		}
	}
}
