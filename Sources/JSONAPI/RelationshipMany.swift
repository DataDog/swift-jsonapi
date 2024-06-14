// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A JSON:API to-many relationship, tagged with the related resource type.
///
/// The `RelationshipMany` type provides a type-safe way to create a JSON:API to-many relationship.
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
/// let authors: RelationshipMany<Person> = ["9", "12"]
///
/// let encoder = JSONEncoder()
/// encoder.outputFormatting = .prettyPrinted
///
/// let data = try encoder.encode(authors)
/// print(String(data: data, encoding: .utf8)!)
///
/// /* Prints:
/// {
///   "data": [
///     {
///       "id": "9",
///       "type": "people"
///     },
///     {
///       "id": "12",
///       "type": "people"
///     }
///   ]
/// }
/// */
/// ```
public struct RelationshipMany<Destination: ResourceLinkageProviding>: Equatable, Codable {
	/// An array containing the resource identifiers of the related resources.
	public var data: [ResourceIdentifier]

	public init(identifiers: [Destination.ID]) {
		self.init(data: identifiers.map(Destination.resourceIdentifier(_:)))
	}

	init(data: [ResourceIdentifier]) {
		self.data = data
	}
}

extension RelationshipMany: ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = Destination.ID

	public init(arrayLiteral elements: ArrayLiteralElement...) {
		self.init(identifiers: elements)
	}
}
