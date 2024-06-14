// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A JSON:API document that includes related resources along with the requested primary resources.
///
/// Some JSON:API responses may include top-level meta information to provide additional details that don't fit into the primary data,
/// such as request identifiers or pagination metadata.
///
/// ```json
/// {
///   "meta": {
///     "requestId": "abcd-1234",
///     "pagination": {
///       "totalPages": 10,
///       "currentPage": 2
///     },
///   },
///   "data": [
///     {
///       "type": "articles",
///       "id": "1",
///       ...
///     },
///     ...
///   ]
/// }
/// ```
///
/// You can use a `CompoundDocument` to access the top-level meta information by providing a suitable `Codable` model for the
/// `meta` property.
///
/// ```swift
/// struct Meta: Equatable, Codable {
///   struct Pagination: Equatable, Codable {
///     let totalPages: Int
///     let currentPage: Int
///   }
///
///   let requestId: String
///   let pagination: Pagination
/// }
///
/// typealias ArticlesDocument = CompoundDocument<[Article], Meta>
///
/// let decoder = JSONAPIDecoder()
/// let document = try decoder.decode(ArticlesDocument.self, from: json)
///
/// let currentPage = document.meta.pagination.currentPage
/// let articles = document.data
/// ```
public struct CompoundDocument<PrimaryData, Meta> {
	private enum CodingKeys: String, CodingKey {
		case data, meta, included
	}

	/// The document's primary data.
	public var data: PrimaryData

	/// A meta value that contains non-standard meta-information.
	public var meta: Meta

	public init(data: PrimaryData, meta: Meta) {
		self.data = data
		self.meta = meta
	}

	public init(data: PrimaryData) where Meta == Unit {
		self.init(data: data, meta: Unit())
	}
}

extension CompoundDocument: Equatable where PrimaryData: Equatable, Meta: Equatable {
}

extension CompoundDocument: Decodable where PrimaryData: Decodable, Meta: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Setup the resource decoder
		let identifiers = try container.decodeIfPresent([ResourceIdentifier].self, forKey: .included) ?? []
		let resourceDecoder = ResourceDecoder(userInfo: decoder.userInfo, identifiers: identifiers) {
			try container.nestedUnkeyedContainer(forKey: .included)
		}
		decoder.userInfo.resourceDecoderStorage?.resourceDecoder = resourceDecoder

		self.data = try container.decode(PrimaryData.self, forKey: .data)

		if let meta = Unit() as? Meta {
			self.meta = meta
		} else {
			self.meta = try container.decode(Meta.self, forKey: .meta)
		}
	}
}

extension CompoundDocument: Encodable where PrimaryData: Encodable, Meta: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		try container.encode(self.data, forKey: .data)

		if Meta.self != Unit.self {
			try container.encode(self.meta, forKey: .meta)
		}

		var includedContainer = container.nestedUnkeyedContainer(forKey: .included)
		try encoder.resourceEncoder?.encodeResources(into: &includedContainer)
	}
}
