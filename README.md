# JSONAPI

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FDataDog%2Fswift-jsonapi%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/DataDog/swift-jsonapi)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FDataDog%2Fswift-jsonapi%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/DataDog/swift-jsonapi)

Effortless JSON:API encoding and decoding in Swift.

## Motivation

Encoding and decoding [JSON:API](https://jsonapi.org) responses using Swift can present several challenges. Here is a
list of some common issues:

* **Complex and nested structures**
  <br> JSON:API responses often have deeply nested structures, including `attributes`, `relationships`, and other
  sections that need careful mapping to Swift types.

* **Included resources**
  <br> The `included` section in JSON:API responses contains related resources we must parse and link to the primary
  data. Managing these relationships in your code requires careful attention to detail.

* **Polymorphic relationships**
  <br> JSON:API supports polymorphic relationships where related resources can be of different types. Decoding these
  relationships involves dealing with multiple possible types for a given relationship.

## Quick start

One of the recurring examples in the JSON:API specification is a response with a
[list of articles](https://jsonapi.org/format/#document-compound-documents). Each *article* has one *author* and zero
or more *comments*. Each *comment* can optionally have one *author*.

We can model these resources as simple structs and annotate them with the `@ResourceWrapper` macro to enable JSON:API
encoding and decoding.

To define the resource's attributes and relationships, we use properties annotated with
`@ResourceAttribute` and `@ResourceRelationship`, respectively.

```swift
@ResourceWrapper(type: "people")
struct Person: Equatable {
  var id: String

  @ResourceAttribute var firstName: String
  @ResourceAttribute var lastName: String
  @ResourceAttribute var twitter: String?
}

@ResourceWrapper(type: "comments")
struct Comment: Equatable {
  var id: String

  @ResourceAttribute var body: String
  @ResourceRelationship var author: Person?
}

@ResourceWrapper(type: "articles")
struct Article: Equatable {
  var id: String

  @ResourceAttribute var title: String
  @ResourceRelationship var author: Person
  @ResourceRelationship var comments: [Comment]
}
```

To decode an array of `Article` values from a JSON:API response, we must use a `JSONAPIDecoder` object. `JSONAPIDecoder` is
a `JSONDecoder` subclass that enables the decoding and embedding of any `included` related resources in the response.

```swift
let decoder = JSONAPIDecoder()
let articles = try decoder.decode([Article].self, from: json)
```

Likewise, we can encode the array of articles back to a JSON:API response using a `JSONAPIEncoder` object. Like its
decoding counterpart, `JSONAPIEncoder` enables encoding related resources into the `included` array.

```swift
let encoder = JSONAPIEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

let data = try encoder.encode(articles)
```

> [!IMPORTANT]
> We advise against mutating relationships in a model annotated with `@ResourceWrapper` since maintaining consistency
> across duplicated instances can be challenging.

## Creating and updating resources

When sending a create or update request to a JSON:API backend, you are not required to provide all the attributes or
relationships. Similarly, when updating a relationship, you only need to provide the related resource identifier
instead of the entire related resource.

The `@ResourceWrapper` macro generates convenience methods to build the body of a create or update request.

Here is an example showing how to obtain the body for a request to create a new article:

```swift
let newArticle = Article.createBody(
  title: "A guide to parsing JSON:API with Swift",
  author: "9"
)

// You can use a regular `JSONEncoder` to encode the request body
let encoder = JSONEncoder()
let data = try encoder.encode(newArticle)
```

Notice that you only need to provide the identifier for the author relationship. The relationship parameter types
encode the related resource type string (`"people"` in this case) for convenience and type safety.

Here is another example showing how to obtain the body for a request to add some comments to an existing article.

```swift
let articleUpdate = Article.updateBody(id: "1", comments: ["5", "12"])
```

## Polymorphic relationships

A polymorphic relationship is a type of relationship where a resource can be related to multiple types of resources.
This means that a single relationship field can reference different resource types.

For example, an `Article` might have a `"contributors"` relationship that can point to both `Person` or
`Organization` resources.

```json
"relationships": {
  "contributors": {
    "data": [
      {
        "type": "people",
        "id": "12"
      },
      {
        "type": "organizations",
        "id": "25"
      }
    ]
  }
}
```

We can leverage the `@ResourceWrapper` macro to model the `Organization` resource, as with the other resources.

```swift
@ResourceWrapper(type: "organizations")
struct Organization: Equatable {
  var id: String

  @ResourceAttribute var name: String
  @ResourceAttribute var contactEmail: String
}
```

For the `"contributors"` relationship, we must create a type that combines the `Person` and `Organization` types.
We can achieve this using an `enum` type with associated values and then annotate it with the `@ResourceUnion` macro.

```swift
@ResourceUnion
enum Contributor: Equatable {
  case person(Person)
  case organization(Organization)
}
```

With that in place, we can add the `contributors` relationship to `Article`.

```swift
@ResourceWrapper(type: "articles")
struct Article: Equatable {
  var id: String

  @ResourceAttribute var title: String

  @ResourceRelationship var author: Person
  @ResourceRelationship var comments: [Comment]
  
  // Both people and organizations can contribute to an article
  @ResourceRelationship var contributors: [Contributor]
}
```

Among other things, the `@ResourceUnion` macro generates an `ID` type that you can use to identify the resources
participating in the union. For example, here is how you can build the body for a request to update the contributors
for an existing article:

```swift
let articleUpdate = Article.updateBody(
  id: "1",
  contributors: [
    .person("12"),
    .organization("24"),
    .person("66")
  ]
)
```

## Top level meta information

Some JSON:API responses may include top-level meta information to provide additional details that don't fit into the
primary data, such as request identifiers or pagination metadata.

```json
{
  "meta": {
    "requestId": "abcd-1234",
    "pagination": {
      "totalPages": 10,
      "currentPage": 2
    },
  },
  "data": [
    {
      "type": "articles",
      "id": "1",
      ...
    },
    ...
  ]
}
```

To get the top-level meta information from a JSON:API response, you must provide a suitable `Codable` model and use
it with the `CompoundDocument` type.

```swift
struct Meta: Equatable, Codable {
  struct Pagination: Equatable, Codable {
    let totalPages: Int
    let currentPage: Int
  }
  
  let requestId: String
  let pagination: Pagination
}

typealias ArticlesDocument = CompoundDocument<[Article], Meta>

let decoder = JSONAPIDecoder()
let document = try decoder.decode(ArticlesDocument.self, from: json)

let currentPage = document.meta.pagination.currentPage
let articles = document.data
```

## Error handling

When decoding a JSON API response, there are instances where you require flexibility and prefer an incomplete response
over an error.

### Missing included resources
If the decoder can't find the resource referenced by a relationship in the `included` section, it throws a
`DecodingError.valueNotFound` error.

We can prevent this in "to-one" relationships by using an optional type.

```swift
@ResourceRelationship var author: Person?
```

For "to-many" relationships, we need to instruct the decoder to ignore missing resources.

```swift
let decoder = JSONAPIDecoder()
decoder.ignoresMissingResources = true

let article = try decoder.decode(Article.self, from: json)
// Ignores any missing resources in the `comments` relationship
```

### Unhandled resource types in polymorphic relationships

When decoding a polymorphic relationship, if the decoder finds a resource type not included in the resource union, it
throws a `JSONAPIDecodingError.unhandledResourceType` error. For instance, consider a scenario where the backend adds
a new type of `Article` contributor that clients are unaware of.

```json
"relationships": {
  "contributors": {
    "data": [
      {
        "type": "people",
        "id": "12"
      },
      {
        "type": "organizations",
        "id": "25"
      },
      {
        "type": "teams",
        "id": "13"
      },
    ]
  }
}
```

We must instruct the decoder to ignore unhandled resource types to prevent this error.

```swift
let decoder = JSONAPIDecoder()
decoder.ignoresUnhandledResourceTypes = true

let article = try decoder.decode(Article.self, from: json)
// Ignores new types of contributors in the `contributors` relationship
```

In addition, for "to-one" relationships, we must use an optional type.

```swift
@ResourceRelationship var reviewer: Contributor?
```

## Status and roadmap

The `JSONAPI` Swift library is production-ready, and we actively use it in the
[Datadog iOS app](https://apps.apple.com/us/app/datadog/id1391380318).
However, we are holding off on releasing version `1.0` until we can cover more parts of the JSON:API specification and
further evaluate community adoption and feedback.

## Installation
### Adding JSONAPI to a Swift package

To use JSONAPI in a Swift Package Manager project, add the following line to the dependencies in your `Package.swift`
file:

```swift
.package(url: "https://github.com/Datadog/swift-jsonapi", from: "0.1.0")
```

Include `"JSONAPI"` as a dependency for your executable target:

```swift
.target(name: "<target>", dependencies: [
  .product(name: "JSONAPI", package: "swift-jsonapi")
]),
```

Finally, add `import JSONAPI` to your source code.

### Adding JSONAPI to an Xcode project

1. From the **File** menu, select **Add Packages…**
1. Enter `https://github.com/Datadog/swift-jsonapi` into the
   *Search or Enter Package URL* search field
1. Link **JSONAPI** to your application target
