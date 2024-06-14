// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceBodyTests: XCTestCase {
	private struct PersonDefinition: ResourceDefinition {
		struct Attributes: Encodable {
			var firstName: String?
			var lastName: String?
			var twitter: String?
		}

		static let resourceType = "people"
	}

	private typealias PersonBody = ResourceBody<String, PersonDefinition>

	private struct CommentDefinition: ResourceDefinition {
		struct Attributes: Encodable {
			var body: String?
		}

		struct Relationships: Encodable {
			var author: RelationshipOne<PersonBody>?
		}

		static let resourceType = "comments"
	}

	private typealias CommentBody = ResourceBody<String, CommentDefinition>

	func testEncodeOnlyAttributes() {
		// given
		let comment = CommentBody(attributes: .init(body: "I like XML better"))

		// then
		assertSnapshot(of: comment, as: .json)
	}

	func testEncodeEmptyRelationshipOne() {
		// given
		let comment = CommentBody(attributes: .init(body: "I like XML better"), relationships: .init(author: .null))

		// then
		assertSnapshot(of: comment, as: .json)
	}

	func testEncodeRelationshipOne() {
		// given
		let comment = CommentBody(
			attributes: .init(body: "I like XML better"),
			relationships: .init(author: "9")
		)

		// then
		assertSnapshot(of: comment, as: .json)
	}
}
