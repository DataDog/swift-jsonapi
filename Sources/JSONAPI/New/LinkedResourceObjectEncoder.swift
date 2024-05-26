import Foundation

final class LinkedResourceObjectEncoder {
	private struct Invocation {
		var invoke: (inout Set<ResourceObjectIdentifier>, inout UnkeyedEncodingContainer) throws -> Void

		init<R>(_ resourceObject: R) where R: ResourceObjectIdentifiable, R: Encodable {
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

	func encode<R>(_ resourceObject: R) where R: ResourceObjectIdentifiable, R: Encodable {
		// Defer encoding to avoid simultaneous accesses
		self.invocations.append(Invocation(resourceObject))
	}

	func encodeIfPresent<R>(_ resourceObject: R?) where R: ResourceObjectIdentifiable, R: Encodable {
		guard let resourceObject else { return }
		self.encode(resourceObject)
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
