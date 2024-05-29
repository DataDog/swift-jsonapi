import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceBodyTests: XCTestCase {
	private struct PersonFieldSet: ResourceFieldSet {
		struct Attributes: Encodable {
			var firstName: String?
			var lastName: String?
			var twitter: String?
		}

		static let resourceType = "people"
	}

	private typealias PersonBody = ResourceBody<String, PersonFieldSet>

	private struct CommentFieldSet: ResourceFieldSet {
		struct Attributes: Encodable {
			var body: String?
		}

		struct Relationships: Encodable {
			var author: ResourceLinkageOne?
		}

		static let resourceType = "comments"
	}

	private typealias CommentBody = ResourceBody<String, CommentFieldSet>

	func testEncodeOnlyAttributes() {
		// given
		let comment = CommentBody(attributes: .init(body: "I like XML better"))

		// then
		assertSnapshot(of: comment, as: .json)
	}

	func testEncodeEmptyRelationshipOne() {
		// given
		let comment = CommentBody(attributes: .init(body: "I like XML better"), relationships: .init(author: .empty))

		// then
		assertSnapshot(of: comment, as: .json)
	}

	func testEncodeRelationshipOne() {
		// given
		let comment = CommentBody(
			attributes: .init(body: "I like XML better"),
			relationships: .init(author: ResourceLinkageOne(data: .init(type: "people", id: "9")))
		)

		// then
		assertSnapshot(of: comment, as: .json)
	}
}
