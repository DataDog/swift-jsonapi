import Foundation

final class ResourceObjectEncoder {
	private struct Invocation {
		var invoke: (inout Set<ResourceObjectIdentifier>, inout UnkeyedEncodingContainer) throws -> Void

		init<R>(_ resourceObject: R) where R: Encodable & ResourceObjectIdentifiable {
			self.invoke = { identifiers, container in
				let identifier = ResourceObjectIdentifier(resourceObject)

				guard !identifiers.contains(identifier) else {
					return
				}

				try container.encode(resourceObject)
				identifiers.insert(identifier)
			}
		}
	}

	private var invocations: [Invocation] = []

	func encode<R>(_ resourceObject: R) where R: Encodable & ResourceObjectIdentifiable {
		// Defer encoding to avoid simultaneous accesses
		self.invocations.append(Invocation(resourceObject))
	}

	func encodeIfPresent<R>(_ resourceObject: R?) where R: Encodable & ResourceObjectIdentifiable {
		guard let resourceObject else { return }
		self.encode(resourceObject)
	}

	func encode<S>(_ sequence: S) where S: Sequence, S.Element: Encodable & ResourceObjectIdentifiable {
		for element in sequence {
			self.encode(element)
		}
	}

	func encodeResourceObjects(into container: inout UnkeyedEncodingContainer) throws {
		// Keep track of the encoded resource objects to avoid duplicates
		var identifiers: Set<ResourceObjectIdentifier> = []

		while !self.invocations.isEmpty {
			// Running an invocation can append more invocations
			try invocations.removeFirst().invoke(&identifiers, &container)
		}
	}
}
