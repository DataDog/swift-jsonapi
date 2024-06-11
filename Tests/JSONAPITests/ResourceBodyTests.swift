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
