// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import JSONAPI
import XCTest

final class SendableTests: XCTestCase {
	private struct SendableAttributes: Codable, Sendable {
		var name: String
	}

	private struct SendableRelationships: Codable, Sendable {
		var owner: RelationshipOne<SendableResource>
	}

	private struct SendableDefinition: ResourceDefinition {
		typealias Attributes = SendableAttributes
		typealias Relationships = SendableRelationships
		static let resourceType = "samples"
	}

	private typealias SendableResource = Resource<String, SendableDefinition>
	private typealias SendableResourceBody = ResourceBody<String, SendableDefinition>

	// MARK: - Unconditional conformances

	func testUnitIsSendable() {
		acceptSendable(JSONAPI.Unit())
	}

	func testResourceIdentifierIsSendable() {
		acceptSendable(ResourceIdentifier(type: "samples", id: "1"))
	}

	func testRelationshipOneIsSendable() {
		acceptSendable(RelationshipOne<SendableResource>(id: "1"))
	}

	func testRelationshipManyIsSendable() {
		acceptSendable(RelationshipMany<SendableResource>(identifiers: ["1", "2"]))
	}

	// MARK: - Conditional conformances

	func testResourceIsSendable_whenGenericsAreSendable() {
		let resource = SendableResource(
			id: "1",
			attributes: .init(name: "n"),
			relationships: .init(owner: RelationshipOne(id: "2"))
		)
		acceptSendable(resource)
	}

	func testResourceBodyIsSendable_whenGenericsAreSendable() {
		let body = SendableResourceBody(
			id: "1",
			attributes: .init(name: "n"),
			relationships: .init(owner: RelationshipOne(id: "2"))
		)
		acceptSendable(body)
	}

	func testInlineRelationshipOneIsSendable_whenDestinationIsSendable() {
		let inline = InlineRelationshipOne(
			SendableResource(
				id: "1",
				attributes: .init(name: "n"),
				relationships: .init(owner: RelationshipOne(id: "2"))
			)
		)
		acceptSendable(inline)
	}

	func testInlineRelationshipManyIsSendable_whenDestinationIsSendable() {
		let inline = InlineRelationshipMany<SendableResource>([])
		acceptSendable(inline)
	}

	func testInlineRelationshipOptionalIsSendable_whenDestinationIsSendable() {
		let inline = InlineRelationshipOptional<SendableResource>(nil)
		acceptSendable(inline)
	}

	func testCompoundDocumentIsSendable_whenGenericsAreSendable() {
		let document = CompoundDocument<SendableResource, JSONAPI.Unit>(
			data: SendableResource(
				id: "1",
				attributes: .init(name: "n"),
				relationships: .init(owner: RelationshipOne(id: "2"))
			)
		)
		acceptSendable(document)
	}

	func testDefaultEmptyIsSendable_whenWrappedIsSendable() {
		acceptSendable(DefaultEmpty<[Int]>(wrappedValue: []))
	}

	private func acceptSendable<T: Sendable>(_ value: T) {
		_ = value
	}
}
