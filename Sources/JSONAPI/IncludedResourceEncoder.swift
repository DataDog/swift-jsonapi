import Foundation

public final class IncludedResourceEncoder {
	static let key = CodingUserInfoKey(rawValue: "JSONAPI.IncludedResourceEncoder")!

	private struct EncodeInvocation {
		var invoke:
			(
				_ identifiers: inout Set<ResourceIdentifier>,
				_ container: inout UnkeyedEncodingContainer
			) throws -> Void

		init<T>(resource: T) where T: EncodableResource {
			self.invoke = { encodedResources, container in
				let resourceIdentifier = ResourceIdentifier(resource)

				guard !encodedResources.contains(resourceIdentifier) else {
					return
				}

				try container.encode(resource)
				encodedResources.insert(resourceIdentifier)
			}
		}
	}

	private var encodeInvocations: [EncodeInvocation] = []

	public func encode<T>(_ value: T) where T: EncodableResource {
		// Defer encoding to avoid simultaneous accesses
		encodeInvocations.append(.init(resource: value))
	}

	public func encodeIfPresent<T>(_ value: T?) where T: EncodableResource {
		guard let value else { return }
		self.encode(value)
	}

	public func encode<S>(_ sequence: S) where S: Sequence, S.Element: EncodableResource {
		for element in sequence {
			self.encode(element)
		}
	}

	public func encodeIfPresent<S>(_ sequence: S?) where S: Sequence, S.Element: EncodableResource {
		guard let sequence else { return }
		self.encode(sequence)
	}

	func encodeResources(into container: inout UnkeyedEncodingContainer) throws {
		var encodedResources: Set<ResourceIdentifier> = []

		// Invocations can enqueue more invocations
		while !encodeInvocations.isEmpty {
			try encodeInvocations.removeFirst().invoke(&encodedResources, &container)
		}
	}
}
