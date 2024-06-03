import Foundation

final class ResourceEncoder {
	private struct Invocation {
		var invoke: (inout Set<ResourceIdentifier>, inout UnkeyedEncodingContainer) throws -> Void

		init<R>(_ resource: R) where R: Encodable & ResourceIdentifiable {
			self.invoke = { identifiers, container in
				let identifier = ResourceIdentifier(resource)

				guard !identifiers.contains(identifier) else {
					return
				}

				try container.encode(resource)
				identifiers.insert(identifier)
			}
		}
	}

	private var invocations: [Invocation] = []

	func encode<R>(_ resource: R) where R: Encodable & ResourceIdentifiable {
		// Defer encoding to avoid simultaneous accesses
		self.invocations.append(Invocation(resource))
	}

	func encodeIfPresent<R>(_ resource: R?) where R: Encodable & ResourceIdentifiable {
		guard let resource else { return }
		self.encode(resource)
	}

	func encode<S>(_ sequence: S) where S: Sequence, S.Element: Encodable & ResourceIdentifiable {
		for element in sequence {
			self.encode(element)
		}
	}

	func encodeResources(into container: inout UnkeyedEncodingContainer) throws {
		// Keep track of the encoded resources to avoid duplicates
		var identifiers: Set<ResourceIdentifier> = []

		while !self.invocations.isEmpty {
			// Running an invocation can append more invocations
			try invocations.removeFirst().invoke(&identifiers, &container)
		}
	}
}
