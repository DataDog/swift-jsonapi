import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceObjectBodyTests: XCTestCase {
	private struct PersonFieldSet: ResourceObjectFieldSet {
		struct Attributes: Encodable {
			var firstName: String?
			var lastName: String?
			var twitter: String?
		}

		static let resourceObjectType = "people"
	}

	private typealias PersonBody = ResourceObjectBody<String, PersonFieldSet>

	private struct CommentFieldSet: ResourceObjectFieldSet {
		struct Attributes: Encodable {
			var body: String?
		}

		struct Relationships: Encodable {
			var author: ResourceLinkageOne?
		}

		static let resourceObjectType = "comments"
	}

	private typealias CommentBody = ResourceObjectBody<String, CommentFieldSet>

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
