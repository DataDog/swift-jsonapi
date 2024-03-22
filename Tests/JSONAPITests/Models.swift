import Foundation
import JSONAPI

struct Person: Equatable {
  private(set) var type: String = "people"

  var id: String
  var firstName: String
  var lastName: String
}

extension Person: CodableResource {
  private enum AttributeCodingKeys: String, CodingKey {
    case firstName, lastName
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: ResourceCodingKeys.self)

    self.type = try container.decode(String.self, forKey: .type)
    self.id = try container.decode(String.self, forKey: .id)

    let attributesContainer = try container.nestedContainer(
      keyedBy: AttributeCodingKeys.self, forKey: .attributes)

    self.firstName = try attributesContainer.decode(String.self, forKey: .firstName)
    self.lastName = try attributesContainer.decode(String.self, forKey: .lastName)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: ResourceCodingKeys.self)

    try container.encode(self.type, forKey: .type)
    try container.encode(self.id, forKey: .id)

    var attributesContainer = container.nestedContainer(
      keyedBy: AttributeCodingKeys.self, forKey: .attributes)

    try attributesContainer.encode(self.firstName, forKey: .firstName)
    try attributesContainer.encode(self.lastName, forKey: .lastName)
  }
}

struct Comment: Equatable {
  private(set) var type: String = "comments"

  var id: String
  var body: String
  var author: Person?
}

extension Comment: CodableResource {
  private enum AttributeCodingKeys: String, CodingKey {
    case body
  }

  private enum RelationshipCodingKeys: String, CodingKey {
    case author
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: ResourceCodingKeys.self)

    self.type = try container.decode(String.self, forKey: .type)
    self.id = try container.decode(String.self, forKey: .id)

    let attributesContainer = try container.nestedContainer(
      keyedBy: AttributeCodingKeys.self, forKey: .attributes)
    self.body = try attributesContainer.decode(String.self, forKey: .body)

    let relationshipsContainer = try container.nestedContainer(
      keyedBy: RelationshipCodingKeys.self, forKey: .relationships)

    if let authorRelationship = try relationshipsContainer.decodeIfPresent(
      RelationshipToOne.self, forKey: .author
    ) {
      guard let includedResourceDecoder = decoder.includedResourceDecoder else {
        throw DocumentDecodingError.includedResourceDecodingNotEnabled
      }

      self.author = try includedResourceDecoder.decodeIfPresent(
        Person.self, forIdentifier: authorRelationship.data
      )
    }
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: ResourceCodingKeys.self)

    try container.encode(self.type, forKey: .type)
    try container.encode(self.id, forKey: .id)

    var attributesContainer = container.nestedContainer(
      keyedBy: AttributeCodingKeys.self, forKey: .attributes)

    try attributesContainer.encode(self.body, forKey: .body)

    var relationshipsContainer = container.nestedContainer(
      keyedBy: RelationshipCodingKeys.self, forKey: .relationships)

    if let author {
      try relationshipsContainer.encode(RelationshipToOne(resource: author), forKey: .author)
    }

    guard let includedResourceEncoder = encoder.includedResourceEncoder else {
      throw DocumentEncodingError.includedResourceEncodingNotEnabled
    }

    if let author {
      try includedResourceEncoder.encode(author)
    }
  }
}

struct Article: Equatable {
  private(set) var type: String = "articles"

  var id: String
  var title: String
  var author: Person
  var comments: [Comment]
}

extension Article: CodableResource {
  private enum AttributeCodingKeys: String, CodingKey {
    case title
  }

  private enum RelationshipCodingKeys: String, CodingKey {
    case author, comments
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: ResourceCodingKeys.self)

    self.type = try container.decode(String.self, forKey: .type)
    self.id = try container.decode(String.self, forKey: .id)

    let attributesContainer = try container.nestedContainer(
      keyedBy: AttributeCodingKeys.self, forKey: .attributes)
    self.title = try attributesContainer.decode(String.self, forKey: .title)

    let relationshipsContainer = try container.nestedContainer(
      keyedBy: RelationshipCodingKeys.self, forKey: .relationships)
    let authorRelationship = try relationshipsContainer.decode(
      RelationshipToOne.self, forKey: .author)
    let commentsRelationship = try relationshipsContainer.decode(
      RelationshipToMany.self, forKey: .comments
    )

    guard let includedResourceDecoder = decoder.includedResourceDecoder else {
      throw DocumentDecodingError.includedResourceDecodingNotEnabled
    }

    self.author = try includedResourceDecoder.decode(
      Person.self, forIdentifier: authorRelationship.data)

    self.comments = try includedResourceDecoder.decode(
      [Comment].self,
      forIdentifiers: commentsRelationship.data
    )
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: ResourceCodingKeys.self)

    try container.encode(self.type, forKey: .type)
    try container.encode(self.id, forKey: .id)

    var attributesContainer = container.nestedContainer(
      keyedBy: AttributeCodingKeys.self, forKey: .attributes)

    try attributesContainer.encode(self.title, forKey: .title)

    var relationshipsContainer = container.nestedContainer(
      keyedBy: RelationshipCodingKeys.self, forKey: .relationships
    )

    try relationshipsContainer.encode(RelationshipToOne(resource: self.author), forKey: .author)
    try relationshipsContainer.encode(
      RelationshipToMany(resources: self.comments), forKey: .comments)

    guard let includedResourceEncoder = encoder.includedResourceEncoder else {
      throw DocumentEncodingError.includedResourceEncodingNotEnabled
    }

    try includedResourceEncoder.encode(self.author)

    for comment in self.comments {
      try includedResourceEncoder.encode(comment)
    }
  }
}
