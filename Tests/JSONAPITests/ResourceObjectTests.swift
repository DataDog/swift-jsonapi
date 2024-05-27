import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceObjectTests: XCTestCase {
	private struct PersonFieldSet: ResourceObjectFieldSet {
		struct Attributes: Equatable, Codable {
			var firstName: String
			var lastName: String
			var twitter: String?
		}

		static let resourceObjectType = "people"
	}

	private typealias Person = ResourceObject<String, PersonFieldSet>

	private struct CommentFieldSet: ResourceObjectFieldSet {
		struct Attributes: Equatable, Codable {
			var body: String
		}

		struct Relationships: Equatable, Codable {
			var author: RelationshipOptional<Person>
		}

		static let resourceObjectType = "comments"
	}

	private typealias Comment = ResourceObject<String, CommentFieldSet>

	private struct ArticleFieldSet: ResourceObjectFieldSet {
		struct Attributes: Equatable, Codable {
			var title: String
		}

		struct Relationships: Equatable, Codable {
			var author: RelationshipOne<Person>
			var comments: RelationshipMany<Comment>
		}

		static let resourceObjectType = "articles"
	}

	private typealias Article = ResourceObject<String, ArticleFieldSet>
	
	private struct CopyrightInfo: Equatable, Codable {
		var copyright: String
		var authors: [String]
	}

	private enum Fixtures {
		static let article = Article(
			id: "1",
			attributes: .init(title: "JSON:API paints my bikeshed!"),
			relationships: .init(
				author: .init(
					Person(id: "9", attributes: .init(firstName: "Dan", lastName: "Gebhardt", twitter: "dgeb"))
				),
				comments: .init(
					[
						.init(
							id: "5",
							attributes: .init(body: "First!"),
							relationships: .init(author: .init(nil))
						),
						.init(
							id: "12",
							attributes: .init(body: "I like XML better"),
							relationships: .init(
								author: .init(
									Person(
										id: "9",
										attributes: .init(
											firstName: "Dan",
											lastName: "Gebhardt",
											twitter: "dgeb"
										)
									)
								)
							)
						),
					]
				)
			)
		)
		static let articles = [article]
		static let copyrightInfo = CopyrightInfo(
			copyright: "Copyright 2024 Datadog Inc.",
			authors: ["Yassir Ramdani", "Nicolas Mulet", "Alan Fineberg", "Guille González"]
		)
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

	func testDecodeNullArray() throws {
		// given
		let json = try XCTUnwrap(#"{ "data": null }"#.data(using: .utf8))

		// when
		let articles = try JSONAPIDecoder().decode([Article].self, from: json)

		// then
		XCTAssertEqual([], articles)
	}

	func testDecodeNullRelationshipOne() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/NullRelationshipOne", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let comment = try JSONAPIDecoder().decode(Comment.self, from: json)

		// then
		XCTAssertNil(comment.author.destination)
	}

	func testDecodeNullRelationshipMany() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/NullRelationshipMany", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let articles = try JSONAPIDecoder().decode([Article].self, from: json)

		// then
		XCTAssertTrue(articles.first!.comments.destination.isEmpty)
	}

	func testDecodeTypeMismatch() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/Person", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		do {
			// when
			_ = try JSONAPIDecoder().decode(Comment.self, from: json)
			XCTFail("Should throw DecodingError.typeMismatch.")
		} catch let DecodingError.typeMismatch(type, context) {
			// then
			XCTAssertEqual(String(describing: type), String(describing: CommentFieldSet.self))
			XCTAssertEqual(
				context.debugDescription, "Resource type 'people' does not match expected type 'comments'")
		} catch {
			XCTFail("Expected DecodingError.typeMismatch but got \(error).")
		}
	}

	func testDecodeMissingResourceObject() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/ArticleMissingResource", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		do {
			// when
			_ = try JSONAPIDecoder().decode(Article.self, from: json)
			XCTFail("Should throw DecodingError.valueNotFound.")
		} catch let DecodingError.valueNotFound(type, context) {
			// then
			XCTAssertEqual(String(describing: type), String(describing: Comment.self))
			XCTAssertEqual(context.debugDescription, "Could not find resource object of type 'comments' with id '5'.")
		} catch {
			XCTFail("Expected DecodingError.valueNotFound but got \(error).")
		}
	}
	
	func testDecodeIgnoresMissingResourceObject() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/ArticleMissingResource", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)
		
		let decoder = JSONAPIDecoder()
		decoder.ignoresMissingResources = true
		
		// when
		let article = try decoder.decode(Article.self, from: json)
		
		// then
		XCTAssertTrue(article.comments.destination.isEmpty)
	}
	
	func testDecodeMeta() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/ArticleMeta", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)
		
		// when
		let document = try JSONAPIDecoder().decode(CompoundDocument<Article, CopyrightInfo>.self, from: json)
		
		// then
		XCTAssertEqual(document, CompoundDocument(data: Fixtures.article, meta: Fixtures.copyrightInfo))
	}

	func testEncodeSingle() throws {
		assertSnapshot(of: Fixtures.article, as: .jsonAPI())
	}

	func testEncodeArray() throws {
		assertSnapshot(of: Fixtures.articles, as: .jsonAPI())
	}
	
	func testEncodeMeta() throws {
		assertSnapshot(of: CompoundDocument(data: Fixtures.article, meta: Fixtures.copyrightInfo), as: .jsonAPI())
	}
}
