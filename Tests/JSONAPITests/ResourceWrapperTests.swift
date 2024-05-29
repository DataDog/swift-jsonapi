import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceWrapperTests: XCTestCase {
	// TODO: Move models here

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

	func testEncodeSingle() {
		assertSnapshot(of: Fixtures.article, as: .jsonAPI())
	}

	func testEncodeArray() {
		assertSnapshot(of: Fixtures.articles, as: .jsonAPI())
	}
}
