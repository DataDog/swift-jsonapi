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
      }
      """
    } expansion: {
      """
      struct Person {
        var id: String
        
        var firstName: String
        var lastName: String
        var birthday: Date?

        static let type = "people"
      }

      extension Person: JSONAPI.CodableResource {
        private enum ResourceAttributeCodingKeys: String, CodingKey {
            case firstName
            case lastName = "last_name"
            case birthday
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
            _ = try container.decode(ResourceType<Self>.self, forKey: .type)
            self.id = try container.decode(String.self, forKey: .id)
            let attributesContainer = try container.nestedContainer(keyedBy: ResourceAttributeCodingKeys.self, forKey: .attributes)
            self.firstName = try attributesContainer.decode(String.self, forKey: .firstName)
            self.lastName = try attributesContainer.decode(String.self, forKey: .lastName)
            self.birthday = try attributesContainer.decodeIfPresent(Date.self, forKey: .birthday)
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: ResourceCodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(self.id, forKey: .id)
            var attributesContainer = container.nestedContainer(keyedBy: ResourceAttributeCodingKeys.self, forKey: .attributes)
            try attributesContainer.encode(self.firstName, forKey: .firstName)
            try attributesContainer.encode(self.lastName, forKey: .lastName)
            try attributesContainer.encodeIfPresent(self.birthday, forKey: .birthday)
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
        var author: Author?

        @ResourceRelationship
        var comments: [Comment]

        @ResourceRelationship(key: "related_articles")
        var related: [Article]?
      }
      """
    } expansion: {
      """
      struct Article {
        var author: Author?
        var comments: [Comment]
        var related: [Article]?

        var id: String

        static let type = "articles"
      }

      extension Article: JSONAPI.CodableResource {

        private enum ResourceRelationshipCodingKeys: String, CodingKey {
            case author
            case comments
            case related = "related_articles"
        }
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
            _ = try container.decode(ResourceType<Self>.self, forKey: .type)
            self.id = try container.decode(String.self, forKey: .id)
            guard let includedResourceDecoder = decoder.includedResourceDecoder else {
              throw DocumentDecodingError.includedResourceDecodingNotEnabled
            }
            let relationshipsContainer = try container.nestedContainer(keyedBy: ResourceRelationshipCodingKeys.self, forKey: .relationships)
            let authorRelationship = try relationshipsContainer.decodeIfPresent(RelationshipToOne.self, forKey: .author)
            if let authorRelationship {
              self.author = try includedResourceDecoder.decodeIfPresent(Author.self, forIdentifier: authorRelationship.data)
            }
            let commentsRelationship = try relationshipsContainer.decode(RelationshipToMany.self, forKey: .comments)
            self.comments = try includedResourceDecoder.decode([Comment].self, forIdentifiers: commentsRelationship.data)
            let relatedRelationship = try relationshipsContainer.decodeIfPresent(RelationshipToMany.self, forKey: .related)
            if let relatedRelationship {
              self.related = try includedResourceDecoder.decodeIfPresent([Article].self, forIdentifiers: relatedRelationship.data)
            }
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: ResourceCodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(self.id, forKey: .id)
            guard let includedResourceEncoder = encoder.includedResourceEncoder else {
              throw DocumentEncodingError.includedResourceEncodingNotEnabled
            }
            var relationshipsContainer = container.nestedContainer(keyedBy: ResourceRelationshipCodingKeys.self, forKey: .relationships)
            if let author {
                    try relationshipsContainer.encode(RelationshipToOne(resource: author), forKey: .author)
                    try includedResourceEncoder.encode(author)
                  }
            try relationshipsContainer.encode(RelationshipToMany(resources: comments), forKey: .comments)
            try includedResourceEncoder.encode(comments)
            if let related {
              try relationshipsContainer.encode(RelationshipToMany(resources: related), forKey: .related)
              try includedResourceEncoder.encode(related)
            }
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

          public var id: String

          public static let type = "people"
      }

      extension Person: JSONAPI.CodableResource {



        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
            _ = try container.decode(ResourceType<Self>.self, forKey: .type)
            self.id = try container.decode(String.self, forKey: .id)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: ResourceCodingKeys.self)
            try container.encode(Self.type, forKey: .type)
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

        static let type = "people"
      }

      extension Person: JSONAPI.CodableResource {


        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
            _ = try container.decode(ResourceType<Self>.self, forKey: .type)
            self.id = try container.decode(Id.self, forKey: .id)
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: ResourceCodingKeys.self)
            try container.encode(Self.type, forKey: .type)
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

          var id: String

          static let type = "people"
      }

      @available(macOS, unavailable)
      extension Person: JSONAPI.CodableResource {


        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
            _ = try container.decode(ResourceType<Self>.self, forKey: .type)
            self.id = try container.decode(String.self, forKey: .id)
        }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: ResourceCodingKeys.self)
            try container.encode(Self.type, forKey: .type)
            try container.encode(self.id, forKey: .id)
        }
      }
      """
    }
  }
}
