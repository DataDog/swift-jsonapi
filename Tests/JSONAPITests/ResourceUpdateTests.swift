import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceUpdateTests: XCTestCase {
	private struct CommentFieldSet: ResourceFieldSet {
		struct Attributes: Encodable {
			var body: String?
		}

		struct Relationships: Encodable {
			var author: ResourceLinkageOne?
		}

		static let resourceType = "comments"
	}

	private typealias CommentUpdate = ResourceUpdate<String, CommentFieldSet>

	func testEncodeOnlyAttributes() {
		// given
		let comment = CommentUpdate(attributes: .init(body: "I like XML better"))

		// then
		assertSnapshot(of: comment, as: .json)
	}

	func testEncodeEmptyRelationshipOne() {
		// given
		let comment = CommentUpdate(attributes: .init(body: "I like XML better"), relationships: .init(author: .empty))

		// then
		assertSnapshot(of: comment, as: .json)
	}

	func testEncodeRelationshipOne() {
		// given
		let comment = CommentUpdate(
			attributes: .init(body: "I like XML better"),
			relationships: .init(author: ResourceLinkageOne(data: .init(type: "people", id: "9")))
		)

		// then
		assertSnapshot(of: comment, as: .json)
	}
}
