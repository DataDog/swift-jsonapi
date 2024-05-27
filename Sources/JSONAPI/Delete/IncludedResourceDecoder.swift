import Foundation

public final class IncludedResourceDecoder {
	private let userInfo: [CodingUserInfoKey: Any]
	private let indexByIdentifier: [ResourceIdentifier: Int]
	private let container: () throws -> any UnkeyedDecodingContainer

	init(
		userInfo: [CodingUserInfoKey: Any],
		identifiers: [ResourceIdentifier],
		container: @escaping () throws -> any UnkeyedDecodingContainer
	) {
		self.userInfo = userInfo
		self.indexByIdentifier = Dictionary(
			zip(identifiers, identifiers.indices),
			uniquingKeysWith: { first, _ in first }
		)
		self.container = container
	}

	public func decode<T>(
		_ type: T.Type,
		forRelationship relationship: RelationshipToOne
	) throws -> T where T: DecodableResource {
		try self.decode(type, forIdentifier: relationship.data)
	}

	public func decode<T>(
		_ type: [T].Type,
		forRelationship relationship: RelationshipToMany
	) throws -> [T] where T: DecodableResource {
		try relationship.data.compactMap {
			do {
				return try self.decode(T.self, forIdentifier: $0)
			} catch JSONAPIDecodingError.unhandledResourceType where userInfo.ignoresUnhandledResourceTypes {
				return nil
			} catch DecodingError.valueNotFound where userInfo.ignoresMissingResources {
				return nil
			}
		}
	}

	public func decodeIfPresent<T>(
		_ type: T.Type,
		forRelationship relationship: OptionalRelationshipToOne?
	) throws -> T? where T: DecodableResource {
		guard let data = relationship?.data else {
			return nil
		}

		do {
			return try decodeIfPresent(type, forIdentifier: data)
		} catch JSONAPIDecodingError.unhandledResourceType where userInfo.ignoresUnhandledResourceTypes {
			return nil
		}
	}

	public func decodeIfPresent<T>(
		_ type: [T].Type,
		forRelationship relationship: RelationshipToMany?
	) throws -> [T]? where T: DecodableResource {
		guard let data = relationship?.data else {
			return nil
		}
		return try data.compactMap {
			try self.decodeIfPresent(T.self, forIdentifier: $0)
		}
	}

	private func decode<T>(
		_ type: T.Type,
		forIdentifier identifier: ResourceIdentifier
	) throws -> T where T: DecodableResource {
		guard let resource = try self.decodeIfPresent(type, forIdentifier: identifier) else {
			throw DecodingError.valueNotFound(
				type,
				.init(
					codingPath: (try? self.container())?.codingPath ?? [],
					debugDescription:
						"Could not find resource of type '\(identifier.type)' with id '\(identifier.id)'."
				)
			)
		}

		return resource
	}

	private func decodeIfPresent<T>(
		_ type: T.Type,
		forIdentifier identifier: ResourceIdentifier
	) throws -> T? where T: DecodableResource {
		guard let index = self.indexByIdentifier[identifier] else {
			return nil
		}

		return try self.decode(T.self, at: index)
	}

	private func decode<T>(_ type: T.Type, at index: Int) throws -> T where T: DecodableResource {
		var container = try self.container()

		precondition(index < container.count!)

		while container.currentIndex < index {
			_ = try container.decode(ResourceIdentifier.self)
		}

		return try container.decode(T.self)
	}
}
