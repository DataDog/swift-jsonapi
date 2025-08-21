// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

public enum ResourceCodingKeys: String, CodingKey {
	case type, id, attributes, relationships
}

/// A JSON:API resource.
///
/// To define a JSON:API resource, you need to provide its type, attributes, and relationships by creating a type that conforms
/// to the ``ResourceDefinition`` protocol.
///
/// The resource attributes may contain any `Codable` property, including complex types involving dictionaries and arrays.
///
/// For resource relationships, use the ``InlineRelationshipOne``, ``InlineRelationshipMany``, or
/// ``InlineRelationshipOptional`` types. These types offer direct access to related resources within the
/// `included` section of a JSON:API document.
///
/// Here is an example of how you can define two related JSON:API resources:
///
/// ```swift
/// struct PersonDefinition: ResourceDefinition {
///   struct Attributes: Equatable, Codable {
///     var firstName: String
///     var lastName: String
///     var twitter: String?
///   }
///
///   static let resourceType = "people"
/// }
///
/// typealias Person = Resource<String, PersonDefinition>
///
/// struct CommentDefinition: ResourceDefinition {
///   struct Attributes: Equatable, Codable {
///     var body: String
///   }
///
///   struct Relationships: Equatable, Codable {
///     var author: RelationshipOptional<Person>
///   }
///
///   static let resourceType = "comments"
/// }
///
/// typealias Comment = Resource<String, CommentDefinition>
/// ```
///
/// Alternatively, you can use the ``ResourceWrapper(type:)`` macro to eliminate the boilerplate required to define
/// a JSON:API resource.
@dynamicMemberLookup
public struct Resource<ID, Definition>: ResourceDefinitionProviding, ResourceIdentifiable, ResourceLinkageProviding
where
	ID: Hashable & CustomStringConvertible,
	Definition: ResourceDefinition
{
	public typealias Attributes = Definition.Attributes
	public typealias Relationships = Definition.Relationships

	public let type: String = Definition.resourceType

	public let id: ID
	public let attributes: Attributes
	public let relationships: Relationships

	public init(id: ID, attributes: Attributes, relationships: Relationships) {
		self.id = id
		self.attributes = attributes
		self.relationships = relationships
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Attributes, V>) -> V {
		self.attributes[keyPath: keyPath]
	}

	public subscript<V>(dynamicMember keyPath: KeyPath<Relationships, V>) -> V {
		self.relationships[keyPath: keyPath]
	}
}

extension Resource where Attributes == Unit {
	public init(id: ID, relationships: Relationships) {
		self.init(id: id, attributes: Unit(), relationships: relationships)
	}
}

extension Resource where Relationships == Unit {
	public init(id: ID, attributes: Attributes) {
		self.init(id: id, attributes: attributes, relationships: Unit())
	}
}

extension Resource where Attributes == Unit, Relationships == Unit {
	public init(id: ID) {
		self.init(id: id, attributes: Unit(), relationships: Unit())
	}
}

extension Resource: Equatable where ID: Equatable, Attributes: Equatable, Relationships: Equatable {
}

extension Resource: Decodable where ID: Decodable, Attributes: Decodable, Relationships: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: ResourceCodingKeys.self)

		let type = try container.decode(String.self, forKey: .type)

		if type != Definition.resourceType {
			throw DecodingError.typeMismatch(
				Definition.self,
				DecodingError.Context(
					codingPath: [ResourceCodingKeys.type],
					debugDescription:
						"Resource type '\(type)' does not match expected type '\(Definition.resourceType)'"
				)
			)
		}

		self.id = try container.decode(ID.self, forKey: .id)

		if let attributes = Unit() as? Attributes {
			self.attributes = attributes
		} else {
			if decoder.userInfo.ignoresMissingResources {
				// Create a custom decoder that provides default values for missing keys
				let attributesDecoder = MissingKeyDecoder(decoder: decoder, container: container, codingPath: decoder.codingPath + [ResourceCodingKeys.attributes])
				self.attributes = try Attributes(from: attributesDecoder)
			} else {
				self.attributes = try container.decode(Attributes.self, forKey: .attributes)
			}
		}

		if let relationships = Unit() as? Relationships {
			self.relationships = relationships
		} else {
			self.relationships = try container.decode(Relationships.self, forKey: .relationships)
		}
	}
}

/// A custom decoder that provides default values for missing keys when ignoring missing resources
private class MissingKeyDecoder: Decoder {
	let decoder: Decoder
	let container: KeyedDecodingContainer<ResourceCodingKeys>
	let codingPath: [CodingKey]
	let userInfo: [CodingUserInfoKey: Any]
	
	init(decoder: Decoder, container: KeyedDecodingContainer<ResourceCodingKeys>, codingPath: [CodingKey]) {
		self.decoder = decoder
		self.container = container
		self.codingPath = codingPath
		self.userInfo = decoder.userInfo
	}
	
	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
		let attributesContainer = try container.nestedContainer(keyedBy: type, forKey: .attributes)
		return KeyedDecodingContainer(MissingKeyContainer(container: attributesContainer, codingPath: codingPath))
	}
	
	func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		try decoder.unkeyedContainer()
	}
	
	func singleValueContainer() throws -> SingleValueDecodingContainer {
		try decoder.singleValueContainer()
	}
}

/// A container that provides default values for missing keys
private struct MissingKeyContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
	let container: KeyedDecodingContainer<Key>
	let codingPath: [CodingKey]
	let allKeys: [Key]
	
	init(container: KeyedDecodingContainer<Key>, codingPath: [CodingKey]) {
		self.container = container
		self.codingPath = codingPath
		self.allKeys = container.allKeys
	}
	
	func contains(_ key: Key) -> Bool {
		container.contains(key)
	}
	
	func decodeNil(forKey key: Key) throws -> Bool {
		if container.contains(key) {
			return try container.decodeNil(forKey: key)
		}
		return false
	}
	
	func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return false
	}
	
	func decode(_ type: String.Type, forKey key: Key) throws -> String {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return ""
	}
	
	func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0.0
	}
	
	func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0.0
	}
	
	func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		return 0
	}
	
	func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
		if container.contains(key) {
			return try container.decode(type, forKey: key)
		}
		
		// For optional types, return nil
		if let optionalType = type as? ExpressibleByNilLiteral.Type {
			return optionalType.init(nilLiteral: ()) as! T
		}
		
		// For other types, try to create a default value
		throw DecodingError.keyNotFound(key, DecodingError.Context(
			codingPath: codingPath + [key],
			debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."
		))
	}
	
	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
		try container.nestedContainer(keyedBy: type, forKey: key)
	}
	
	func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
		try container.nestedUnkeyedContainer(forKey: key)
	}
	
	func superDecoder() throws -> Decoder {
		try container.superDecoder()
	}
	
	func superDecoder(forKey key: Key) throws -> Decoder {
		try container.superDecoder(forKey: key)
	}
}

extension Resource: Encodable where ID: Encodable, Attributes: Encodable, Relationships: Encodable {
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: ResourceCodingKeys.self)

		try container.encode(self.type, forKey: .type)
		try container.encode(self.id, forKey: .id)

		if Attributes.self != Unit.self {
			try container.encode(self.attributes, forKey: .attributes)
		}

		if Relationships.self != Unit.self {
			try container.encode(self.relationships, forKey: .relationships)
		}
	}
}
