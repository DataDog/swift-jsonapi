// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// The definition of a JSON:API resource, including the type, attributes, and relationships.
///
/// You define a JSON:API resource type, attributes, and relationships by creating a type that
/// conforms to the `ResourceDefinition` protocol.
///
/// The `Attributes` associated type may contain any `Codable` property, including
/// complex types involving dictionaries and arrays.
///
/// The properties defined by the `Relationships` associated type represent "relationships"
/// to other resources.
///
/// You will likely want the related resources embedded in the parent model. For these situations,
/// you can use the ``InlineRelationshipOne``, ``InlineRelationshipMany``, or
/// ``InlineRelationshipOptional`` types. These types decode the related resources
/// from the `included` section of a JSON:API response.
///
/// The ``Resource`` type uses a `ResourceDefinition` conforming type as a
/// parameter to decode and encode the attributes and relationships of JSON:API resources
/// that match the defined resource type string.
///
/// Here is an example of how you can define two related JSON:API resources:
///
/// ```swift
/// struct PersonDefinition: ResourceDefinition {
///   struct Attributes: Equatable, Codable {
///     var firstName: String
///     var lastName: String
///     var twitter: String?
///   }
///
///   static let resourceType = "people"
/// }
///
/// typealias Person = Resource<String, PersonDefinition>
///
/// struct CommentDefinition: ResourceDefinition {
///   struct Attributes: Equatable, Codable {
///     var body: String
///   }
///
///   struct Relationships: Equatable, Codable {
///     var author: RelationshipOptional<Person>
///   }
///
///   static let resourceType = "comments"
/// }
///
/// typealias Comment = Resource<String, CommentDefinition>
/// ```
///
/// When creating or updating a JSON:API resource, you are not required to provide an
/// identifier, nor all attributes or relationships. The recommended approach for this use case
/// is to create an alternative resource definition and use it with ``ResourceBody``.
///
/// Here is an example of how you can create an alternative definition for creating and
/// updating resources of type `"comments"`:
///
/// ```swift
/// struct CommentBodyDefinition: ResourceDefinition {
///   struct Attributes: Encodable {
///     var body: String?
///   }
///
///   struct Relationships: Encodable {
///     var author: RelationshipOne<Person>?
///   }
///
///   static let resourceType = "comments"
/// }
///
/// typealias CommentBody = ResourceBody<String, CommentBodyDefinition>
/// ```
///
/// It is worth noting that you need to use the ``RelationshipOne`` and
/// ``RelationshipMany`` types to define relationships since only the
/// relationship, not the related resource, is required in a creation or update operation.
public protocol ResourceDefinition {
	associatedtype Attributes = Unit
	associatedtype Relationships = Unit

	/// The JSON:API resource type string.
	static var resourceType: String { get }
}
