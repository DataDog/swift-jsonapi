// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A JSON:API resource payload for create or update requests.
///
/// When creating or updating a JSON:API resource, you are not required to provide an
/// identifier, nor all attributes or relationships. The recommended approach for this use case
/// is to create an alternative resource definition and use it with `ResourceBody`.
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
/// Alternatively, consider using the ``ResourceWrapper(type:)`` macro, which generates convenient methods for building
/// the body of create or update requests.
public struct ResourceBody<ID, Definition>: Encodable
where
	ID: Hashable & Encodable,
	Definition: ResourceDefinition,
	Definition.Attributes: Encodable,
	Definition.Relationships: Encodable
{
	public typealias Attributes = Definition.Attributes
	public typealias Relationships = Definition.Relationships

	public let type: String = Definition.resourceType

	public var id: ID?
	public var attributes: Attributes?
	public var relationships: Relationships?

	public init(id: ID? = nil, attributes: Attributes? = nil, relationships: Relationships? = nil) {
		self.id = id
		self.attributes = attributes
		self.relationships = relationships
	}

	private enum CodingKeys: String, CodingKey {
		case data
	}

	public func encode(to encoder: any Encoder) throws {
		func isEmpty<T>(_ value: T) -> Bool {
			let mirror = Mirror(reflecting: value)

			for child in mirror.children {
				let childMirror = Mirror(reflecting: child.value)

				guard childMirror.displayStyle == .optional else {
					return false
				}

				guard childMirror.children.isEmpty else {
					return false
				}
			}

			return true
		}

		var container = encoder.container(keyedBy: CodingKeys.self)
		var nestedContainer = container.nestedContainer(keyedBy: ResourceCodingKeys.self, forKey: .data)

		try nestedContainer.encode(self.type, forKey: .type)
		try nestedContainer.encodeIfPresent(self.id, forKey: .id)

		if Attributes.self != Unit.self, let attributes, !isEmpty(attributes) {
			try nestedContainer.encode(attributes, forKey: .attributes)
		}

		if Relationships.self != Unit.self, let relationships, !isEmpty(relationships) {
			try nestedContainer.encode(relationships, forKey: .relationships)
		}
	}
}

extension ResourceBody: ResourceLinkageProviding {
	public static func resourceIdentifier(_ id: ID) -> ResourceIdentifier {
		ResourceIdentifier(type: Definition.resourceType, id: String(describing: id))
	}
}

extension ResourceBody where Attributes == Unit {
	public init(id: ID? = nil, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension ResourceBody where Relationships == Unit {
	public init(id: ID? = nil, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension ResourceBody: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}
