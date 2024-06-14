// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A JSON:API to-one relationship, tagged with the related resource type.
///
/// The `RelationshipOne` type provides a type-safe way to create a JSON:API to-one relationship.
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
/// let author: RelationshipOne<Person> = "9"
///
/// let encoder = JSONEncoder()
/// encoder.outputFormatting = .prettyPrinted
///
/// let data = try encoder.encode(author)
/// print(String(data: data, encoding: .utf8)!)
///
/// /* Prints:
/// {
///   "data": {
///     "id": "9",
///     "type": "people"
///   }
/// }
/// */
/// ```
public struct RelationshipOne<Destination: ResourceLinkageProviding>: Equatable, Codable {
	/// A `null` to-one relationship.
	public static var null: RelationshipOne {
		RelationshipOne(data: nil)
	}

	public var data: ResourceIdentifier?

	public init(id: Destination.ID) {
		self.init(data: Destination.resourceIdentifier(id))
	}

	init(data: ResourceIdentifier?) {
		self.data = data
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		// explicitly encode nil values
		try container.encode(self.data, forKey: .data)
	}
}

extension RelationshipOne: ExpressibleByUnicodeScalarLiteral where Destination.ID: ExpressibleByUnicodeScalarLiteral {
	public typealias UnicodeScalarLiteralType = Destination.ID.UnicodeScalarLiteralType

	public init(unicodeScalarLiteral: UnicodeScalarLiteralType) {
		self.init(id: Destination.ID(unicodeScalarLiteral: unicodeScalarLiteral))
	}
}

extension RelationshipOne: ExpressibleByExtendedGraphemeClusterLiteral
where
	Destination.ID: ExpressibleByExtendedGraphemeClusterLiteral
{
	public typealias ExtendedGraphemeClusterLiteralType = Destination.ID.ExtendedGraphemeClusterLiteralType

	public init(extendedGraphemeClusterLiteral: ExtendedGraphemeClusterLiteralType) {
		self.init(id: Destination.ID(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
	}
}

extension RelationshipOne: ExpressibleByStringLiteral where Destination.ID: ExpressibleByStringLiteral {
	public typealias StringLiteralType = Destination.ID.StringLiteralType

	public init(stringLiteral: StringLiteralType) {
		self.init(id: Destination.ID(stringLiteral: stringLiteral))
	}
}
