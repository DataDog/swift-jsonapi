/// Transforms a Swift struct into a JSON:API resource that can be encoded or decoded from a JSON:API response.
///
/// Annotate your models with the `@ResourceWrapper` macro to enable JSON:API encoding and decoding. At build time,
/// the macro expands to provide conformance to `Codable`, ``ResourceDefinitionProviding``,
/// ``ResourceLinkageProviding`` and ``ResourceIdentifiable`` protocols.
///
/// ```swift
/// @ResourceWrapper(type: "people")
/// struct Person: Equatable {
///   var id: String
///
///   @ResourceAttribute var firstName: String
///   @ResourceAttribute var lastName: String
///   @ResourceAttribute var twitter: String?
/// }
///
/// @ResourceWrapper(type: "comments")
/// struct Comment: Equatable {
///   var id: String
///
///   @ResourceAttribute var body: String
///   @ResourceRelationship var author: Person?
/// }
///
/// @ResourceWrapper(type: "articles")
/// struct Article: Equatable {
///   var id: String
///
///   @ResourceAttribute var title: String
///   @ResourceRelationship var author: Person
///   @ResourceRelationship var comments: [Comment]
/// }
/// ```
///
/// The macro also generates convenience methods to build the body of a create or update request.
///
/// ```swift
/// let newArticle = Article.createBody(
///   title: "A guide to parsing JSON:API with Swift",
///   author: "9"
/// )
///
/// let articleUpdate = Article.updateBody(id: "1", comments: ["5", "12"])
///
/// // You can use a regular `JSONEncoder` to encode the request body
/// let encoder = JSONEncoder()
/// let data = try encoder.encode(newArticle)
/// ```
///
/// - Parameters:
///   - type: The JSON:API resource type.
@attached(
	extension,
	conformances: ResourceIdentifiable, ResourceDefinitionProviding, ResourceLinkageProviding, Codable,
	names: named(ID), named(Definition), named(BodyDefinition), named(Wrapped), named(Body), named(type),
	named(init(from:)), named(encode(to:)), named(createBody), named(updateBody)
)
public macro ResourceWrapper(type: String) = #externalMacro(module: "JSONAPIMacros", type: "ResourceWrapperMacro")

/// Marks a property as a JSON:API resource attribute.
///
/// Annotate the model properties corresponding to the JSON:API resource attributes with the `@ResourceAttribute` macro,
/// and optionally provide the JSON key if it differs from the property name.
///
/// ```swift
/// @ResourceWrapper(type: "people")
/// struct Person: Equatable {
///   var id: String
///
///   @ResourceAttribute(key: "first") var firstName: String
///   @ResourceAttribute(key: "last") var lastName: String
///   @ResourceAttribute var twitter: String?
/// }
/// ```
///
/// - Parameters:
///   - key: Optional coding key for the resource attribute.
@attached(accessor, names: named(willSet))
public macro ResourceAttribute(key: String? = nil) =
	#externalMacro(
		module: "JSONAPIMacros",
		type: "ResourceAttributeMacro"
	)

/// Marks a property as a JSON:API resource relationship.
///
/// Annotate the model properties corresponding to the JSON:API resource relationships with the `@ResourceRelationship` macro,
/// and optionally provide the JSON key if it differs from the property name.
///
/// The property type must be either a ``Resource``, another type annotated with the `@ResourceWrapper` macro,
/// an optional resource, or an array of resources.
///
/// At build time, the ``@ResourceWrapper`` macro generates a ``ResourceDefinition`` implementation, mapping the properties
/// annotated with the `@ResourceRelationship` macro as follows:
///
/// - Single resource properties are mapped to ``InlineRelationshipOne`` properties.
/// - Optional resource properties are mapped to ``InlineRelationshipOptional`` properties.
/// - Array of resource properties are mapped to ``InlineRelationshipMany`` properties.
///
/// ```swift
/// @ResourceWrapper(type: "articles")
/// struct Article: Equatable {
///   var id: String
///
///   @ResourceAttribute var title: String
///
///   @ResourceRelationship(key: "writtenBy") var author: Person
///   @ResourceRelationship var comments: [Comment]
/// }
/// ```
///
/// - Parameters:
///   - key: Optional coding key for the resource relationship.
@attached(accessor, names: named(willSet))
public macro ResourceRelationship(key: String? = nil) =
	#externalMacro(
		module: "JSONAPIMacros",
		type: "ResourceRelationshipMacro"
	)

/// Transforms a Swift enum into a JSON:API resource representing the union of two or more resource types.
///
/// Annotate an enum type with the `@ResourceUnion` macro when you need to model polymorphic relationships.
/// At build time, the macro expands to provide conformance to `Codable`, ``ResourceLinkageProviding`` and
/// ``ResourceIdentifiable`` protocols.
///
/// The annotated enum type must have a `case` with an associated value for each resource type it can represent.
///
/// ```swift
/// @ResourceUnion
/// enum Contributor: Equatable {
///   case person(Person)
///   case organization(Organization)
/// }
///
/// @ResourceWrapper(type: "articles")
/// struct Article: Equatable {
///   var id: String
///
///   @ResourceAttribute var title: String
///
///   // Both people and organizations can contribute to an article
///   @ResourceRelationship var contributors: [Contributor]
/// }
/// ```
///
/// The macro generates an ID type that can unambiguously represent identifiers for the resource types involved in the union.
/// For example, here is how you can build the body for a request to update the contributors for an existing article.
///
/// ```swift
/// let articleUpdate = Article.updateBody(
///   id: "1",
///   contributors: [
/// 	.person("12"),
/// 	.organization("24"),
/// 	.person("66")
///   ]
/// )
/// ```
@attached(
	extension,
	conformances: ResourceIdentifiable, ResourceLinkageProviding, Codable,
	names: named(type), named(id), named(ID), named(resourceIdentifier), named(init(from:)), named(encode(to:))
)
public macro ResourceUnion() = #externalMacro(module: "JSONAPIMacros", type: "ResourceUnionMacro")
