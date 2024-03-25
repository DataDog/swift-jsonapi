import Foundation
import JSONAPI

@CodableResource(type: "people")
struct Person: Equatable {
  var id: String

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
