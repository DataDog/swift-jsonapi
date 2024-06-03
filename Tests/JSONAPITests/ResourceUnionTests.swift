import JSONAPI
import SnapshotTesting
import XCTest

final class ResourceUnionTests: XCTestCase {
	@ResourceWrapper(type: "images")
	fileprivate struct Image: Equatable {
		var id: String

		@ResourceAttribute
		var url: URL

		@ResourceAttribute
		var width: Int

		@ResourceAttribute
		var height: Int
	}

	@ResourceWrapper(type: "audios")
	fileprivate struct Audio: Equatable {
		var id: String

		@ResourceAttribute
		var url: URL

		@ResourceAttribute
		var title: String
	}

	@ResourceUnion
	fileprivate enum Attachment: Equatable {
		case image(ResourceUnionTests.Image)
		case audio(ResourceUnionTests.Audio)
	}

	@ResourceWrapper(type: "single_attachment_messages")
	fileprivate struct SingleAttachmentMessage: Equatable {
		var id: String

		@ResourceAttribute
		var text: String

		@ResourceRelationship
		var attachment: ResourceUnionTests.Attachment?
	}

	@ResourceWrapper(type: "messages")
	fileprivate struct Message: Equatable {
		var id: String

		@ResourceAttribute
		var text: String

		@ResourceRelationship
		var attachments: [ResourceUnionTests.Attachment]
	}

	private enum Fixtures {
		static let singleAttachmentMessage = SingleAttachmentMessage(
			id: "1",
			text: "Look what I just found!",
			attachment: .image(
				Image(
					id: "42",
					url: URL(string: "https://via.placeholder.com/640x480")!,
					width: 640,
					height: 480
				)
			)
		)
		static let message = Message(
			id: "1",
			text: "Look what I just found!",
			attachments: [
				.image(
					Image(
						id: "42",
						url: URL(string: "https://via.placeholder.com/640x480")!,
						width: 640,
						height: 480
					)
				),
				.audio(
					Audio(
						id: "66",
						url: URL(string: "https://audio.com/NeverGonnaGiveYouUp.mp3")!,
						title: "Never Gonna Give You Up"
					)
				),
			]
		)
	}

	func testDecodePolymorphicRelationshipOne() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/PolymorphicRelationshipOne", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let message = try JSONAPIDecoder().decode(SingleAttachmentMessage.self, from: json)

		// then
		XCTAssertEqual(message, Fixtures.singleAttachmentMessage)
	}

	func testDecodePolymorphicRelationshipMany() throws {
		// given
		let json = try XCTUnwrap(
			Bundle.module.url(forResource: "Fixtures/PolymorphicRelationshipMany", withExtension: "json").map {
				try Data(contentsOf: $0)
			}
		)

		// when
		let message = try JSONAPIDecoder().decode(Message.self, from: json)

		// then
		XCTAssertEqual(message, Fixtures.message)
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
			_ = try JSONAPIDecoder().decode(SingleAttachmentMessage.self, from: json)
			XCTFail("Should throw JSONAPIDecodingError.unhandledResourceType.")
		} catch let JSONAPIDecodingError.unhandledResourceType(unionType, resourceType) {
			// then
			XCTAssertEqual(String(describing: unionType), String(describing: Attachment.self))
			XCTAssertEqual(resourceType, "videos")
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
		let message = try decoder.decode(SingleAttachmentMessage.self, from: json)

		// then
		XCTAssertEqual(SingleAttachmentMessage(id: "1", text: "Look what I just found!"), message)
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
		let message = try decoder.decode(Message.self, from: json)

		// then
		XCTAssertEqual(
			Message(
				id: "1",
				text: "Look what I just found!",
				attachments: [
					.audio(
						Audio(
							id: "66",
							url: URL(string: "https://audio.com/NeverGonnaGiveYouUp.mp3")!,
							title: "Never Gonna Give You Up"
						)
					)
				]
			),
			message
		)
	}

	func testEncodePolymorphicRelationshipOne() {
		assertSnapshot(of: Fixtures.singleAttachmentMessage, as: .jsonAPI())
	}

	func testEncodePolymorphicRelationshipMany() {
		assertSnapshot(of: Fixtures.message, as: .jsonAPI())
	}
}
