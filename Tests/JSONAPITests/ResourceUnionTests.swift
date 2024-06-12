import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceUnionTests: XCTestCase {
	@ResourceWrapper(type: "people")
	fileprivate struct Person: Equatable {
		var id: String

		@ResourceAttribute var firstName: String
		@ResourceAttribute var lastName: String
		@ResourceAttribute var twitter: String?
	}

	@ResourceWrapper(type: "organizations")
	fileprivate struct Organization: Equatable {
		var id: UUID

		@ResourceAttribute var name: String
		@ResourceAttribute var contactEmail: String
	}

	@ResourceUnion
	fileprivate enum Contributor: Equatable {
		case person(ResourceUnionTests.Person)
		case organization(ResourceUnionTests.Organization)
	}

	@ResourceWrapper(type: "articles")
	fileprivate struct Article: Equatable {
		var id: String

		@ResourceAttribute var title: String

		@ResourceRelationship var author: ResourceUnionTests.Person
		@ResourceRelationship var contributors: [ResourceUnionTests.Contributor]
		@ResourceRelationship var reviewer: ResourceUnionTests.Contributor?
	}

	private enum Fixtures {
		static let article = Article(
			id: "1",
			title: "A guide to parsing JSON:API with Swift",
			author: Person(
				id: "9",
				firstName: "John",
				lastName: "Doe",
				twitter: "johndoe"
			),
			contributors: [
				.person(Person(id: "12", firstName: "Jane", lastName: "Smith")),
				.organization(
					Organization(
						id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
						name: "Swift Enthusiasts",
						contactEmail: "contact@swiftenthusiasts.org"
					)
				),
			],
			reviewer: .organization(
				Organization(
					id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
					name: "Swift Enthusiasts",
					contactEmail: "contact@swiftenthusiasts.org"
				)
			)
		)
	}

	func testDecodePolymorphicRelationship() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/ArticlePolymorphic", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let article = try JSONAPIDecoder().decode(Article.self, from: json)

		// then
		XCTAssertEqual(article, Fixtures.article)
	}

	func testDecodeUnhandledResourceType() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/UnhandledResourceTypeRelationshipOne", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		do {
			// when
			_ = try JSONAPIDecoder().decode(Article.self, from: json)
			XCTFail("Should throw JSONAPIDecodingError.unhandledResourceType.")
		} catch let JSONAPIDecodingError.unhandledResourceType(unionType, resourceType) {
			// then
			XCTAssertEqual(String(describing: unionType), String(describing: Contributor.self))
			XCTAssertEqual(resourceType, "teams")
		} catch {
			XCTFail("Expected JSONAPIDecodingError.unhandledResourceType but got \(error).")
		}
	}

	func testDecodeIgnoresUnhandledResourceType() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/UnhandledResourceTypeRelationshipOne", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		let decoder = JSONAPIDecoder()
		decoder.ignoresUnhandledResourceTypes = true

		// when
		let article = try decoder.decode(Article.self, from: json)

		// then
		XCTAssertNil(article.reviewer)
	}

	func testDecodeIgnoresUnhandledResourceTypeMany() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/UnhandledResourceTypeRelationshipMany", withExtension: "json").map
			{
				try Data(contentsOf: $0)
			}
		)

		let decoder = JSONAPIDecoder()
		decoder.ignoresUnhandledResourceTypes = true

		// when
		let article = try decoder.decode(Article.self, from: json)

		// then
		XCTAssertEqual(article, Fixtures.article)
	}

	func testEncodePolymorphicRelationship() {
		assertSnapshot(of: Fixtures.article, as: .jsonAPI())
	}

	func testEncodeBody() {
		// given
		let articleBody = Article.createBody(
			title: "A guide to parsing JSON:API with Swift",
			contributors: [
				.person("12"),
				.organization(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!),
			],
			reviewer: RelationshipOne(
				id: .organization(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
			)
		)

		// then
		assertSnapshot(of: articleBody, as: .json)
	}
}
