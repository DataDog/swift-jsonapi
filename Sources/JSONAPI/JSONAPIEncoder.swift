// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// An object that encodes JSON:API documents.
///
/// The example below demonstrates how to encode an `Article` value to a
/// [JSON:API](https://jsonapi.org) document. The types involved use
/// the ``ResourceWrapper(type:)`` macro to enable JSON:API encoding.
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
///
/// let article = Article(
///   id: "1",
///   title: "JSON:API paints my bikeshed!",
///   author: Person(id: "9", firstName: "Dan", lastName: "Gebhardt", twitter: "dgeb"),
///   comments: [
///     Comment(id: "5", body: "First!"),
///     Comment(
///       id: "12",
///       body: "I like XML better",
///       author: Person(id: "9", firstName: "Dan", lastName: "Gebhardt", twitter: "dgeb")
///     ),
///   ]
/// )
///
/// let encoder = JSONAPIEncoder()
/// encoder.outputFormatting = .prettyPrinted
///
/// let data = try encoder.encode(article)
/// print(String(data: data, encoding: .utf8)!)
///
/// /* Prints:
///  {
///    "data": {
///      "type": "articles",
///      "id": "1",
///      "attributes": {
///        "title": "JSON:API paints my bikeshed!"
///      },
///      "relationships": {
///        "author": {
///          "data": {
///            "id": "9",
///            "type": "people"
///          }
///        },
///        "comments": {
///          "data": [
///            ...
///          ]
///        }
///      }
///    },
///    "included": [
///      {
///        "id": "9",
///        "type": "people",
///        "attributes": {
///          "firstName": "Dan",
///          "lastName": "Gebhardt",
///          "twitter": "dgeb"
///        }
///      },
///      ...
///    ]
///  }
/// */
/// ```
public class JSONAPIEncoder: JSONEncoder {
	public override init() {
		super.init()
		self.userInfo.resourceEncoder = ResourceEncoder()
	}

	public func encode<R>(_ value: R) throws -> Data where R: ResourceIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}

	public func encode<C>(
		_ value: C
	) throws -> Data where C: Collection & Encodable, C.Element: ResourceIdentifiable & Encodable {
		try self.encode(CompoundDocument(data: value))
	}
}

extension Encoder {
	var resourceEncoder: ResourceEncoder? {
		self.userInfo.resourceEncoder
	}
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
	fileprivate var resourceEncoder: ResourceEncoder? {
		get {
			self[.resourceEncoder] as? ResourceEncoder
		}
		set {
			self[.resourceEncoder] = newValue
		}
	}
}

extension CodingUserInfoKey {
	fileprivate static let resourceEncoder = Self(rawValue: "JSONAPI.resourceEncoder")!
}
