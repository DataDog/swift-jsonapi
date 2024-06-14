// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceWrapperTests: XCTestCase {
	@ResourceWrapper(type: "people")
	fileprivate struct Person: Equatable {
		var id: String

		@ResourceAttribute var firstName: String
		@ResourceAttribute var lastName: String
		@ResourceAttribute var twitter: String?
	}

	@ResourceWrapper(type: "comments")
	fileprivate struct Comment: Equatable {
		var id: String

		@ResourceAttribute var body: String
		@ResourceRelationship var author: ResourceWrapperTests.Person?
	}

	@ResourceWrapper(type: "articles")
	fileprivate struct Article: Equatable {
		var id: String

		@ResourceAttribute var title: String
		@ResourceRelationship var author: ResourceWrapperTests.Person
		@ResourceRelationship var comments: [ResourceWrapperTests.Comment]
	}

	@ResourceWrapper(type: "schedules")
	fileprivate struct Schedule: Equatable {
		var id: String

		@ResourceAttribute
		var name: String

		@ResourceAttribute
		var tags: [String]
	}

	private enum Fixtures {
		static let article = Article(
			id: "1",
			title: "JSON:API paints my bikeshed!",
			author: Person(id: "9", firstName: "Dan", lastName: "Gebhardt", twitter: "dgeb"),
			comments: [
				Comment(id: "5", body: "First!"),
				Comment(
					id: "12",
					body: "I like XML better",
					author: Person(id: "9", firstName: "Dan", lastName: "Gebhardt", twitter: "dgeb")
				),
			]
		)
		static let articles = [article]
	}

	func testDecodeSingle() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/Article", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let article = try JSONAPIDecoder().decode(Article.self, from: json)

		// then
		XCTAssertEqual(article, Fixtures.article)
	}

	func testDecodeArray() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/Articles", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let articles = try JSONAPIDecoder().decode([Article].self, from: json)

		// then
		XCTAssertEqual(articles, Fixtures.articles)
	}

	func testDecodeNullArrayAttribute() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/NullArrayAttribute", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let schedules = try JSONAPIDecoder().decode([Schedule].self, from: json)

		// then
		XCTAssertEqual(
			[
				Schedule(id: "1", name: "Some schedule", tags: ["some tag"]),
				Schedule(id: "2", name: "Some other schedule", tags: []),
			],
			schedules
		)
	}

	func testEncodeSingle() {
		assertSnapshot(of: Fixtures.article, as: .jsonAPI())
	}

	func testEncodeArray() {
		assertSnapshot(of: Fixtures.articles, as: .jsonAPI())
	}

	func testEncodeBodyOnlyAttributes() {
		// given
		let commentUpdate = Comment.updateBody(id: "1", body: "I like XML better")

		// then
		assertSnapshot(of: commentUpdate, as: .json)
	}

	func testEncodeBodyNullRelationship() {
		// given
		let commentUpdate = Comment.updateBody(id: "1", body: "I like XML better", author: .null)

		// then
		assertSnapshot(of: commentUpdate, as: .json)
	}

	func testEncodeBodyRelationships() {
		// given
		let articleUpdate = Article.updateBody(id: "1", author: "9", comments: ["5", "12"])

		// then
		assertSnapshot(of: articleUpdate, as: .json)
	}
}
