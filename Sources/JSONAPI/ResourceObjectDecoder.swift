import Foundation

final class ResourceObjectDecoder {
	private let userInfo: [CodingUserInfoKey: Any]
	private let indexByIdentifier: [ResourceObjectIdentifier: Int]
	private let container: () throws -> any UnkeyedDecodingContainer

	init(
		userInfo: [CodingUserInfoKey: Any],
		identifiers: [ResourceObjectIdentifier],
		container: @escaping () throws -> any UnkeyedDecodingContainer
	) {
		self.userInfo = userInfo
		self.indexByIdentifier = Dictionary(
			zip(identifiers, identifiers.indices),
			uniquingKeysWith: { first, _ in first }
		)
		self.container = container
	}

	func decode<R>(_ type: R.Type, identifier: ResourceObjectIdentifier) throws -> R where R: Decodable {
		guard let resource = try self.decodeIfPresent(type, identifier: identifier) else {
			throw DecodingError.valueNotFound(
				type,
				.init(
					codingPath: (try? self.container())?.codingPath ?? [],
					debugDescription: """
						Could not find resource object of type '\(identifier.type)' with id '\(identifier.id)'.
						"""
				)
			)
		}

		return resource
	}

	func decodeIfPresent<R>(
		_ type: R.Type,
		identifier: ResourceObjectIdentifier?
	) throws -> R? where R: Decodable {
		guard let identifier, let index = self.indexByIdentifier[identifier] else {
			return nil
		}

		do {
			return try self.decode(R.self, at: index)
		} catch JSONAPIDecodingError.unhandledResourceType where userInfo.ignoresUnhandledResourceTypes {
			return nil
		}
	}

	func decode<R>(
		_ type: [R].Type,
		identifiers: [ResourceObjectIdentifier]
	) throws -> [R] where R: Decodable {
		try identifiers.compactMap { identifier in
			do {
				return try self.decode(R.self, identifier: identifier)
			} catch JSONAPIDecodingError.unhandledResourceType where userInfo.ignoresUnhandledResourceTypes {
				return nil
			} catch DecodingError.valueNotFound where userInfo.ignoresMissingResources {
				return nil
			}
		}
	}

	private func decode<R>(
		_ type: R.Type,
		at index: Int
	) throws -> R where R: Decodable {
		var container = try self.container()

		precondition(index < container.count!)

		while container.currentIndex < index {
			_ = try container.decode(ResourceObjectIdentifier.self)
		}

		return try container.decode(R.self)
	}
}