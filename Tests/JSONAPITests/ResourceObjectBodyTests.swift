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
			// TODO: RelationshipOptionalRef
			var author: RelationshipOneRef<String, PersonFieldSet>?
		}

		static let resourceObjectType = "comments"
	}
	
	private typealias CommentBody = ResourceObjectBody<String, CommentFieldSet>
	
	func testEncodeAttributes() {
		// given
		let person = PersonBody(attributes: .init(firstName: "Guille", lastName: "González"))
		
		// then
		assertSnapshot(of: person, as: .json)
	}
}
