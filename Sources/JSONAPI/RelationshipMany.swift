import Foundation

public struct RelationshipMany<Destination: ResourceLinkageProviding>: Equatable, Codable {
	public var data: [ResourceIdentifier]

	public init(identifiers: [Destination.ID]) {
		self.init(data: identifiers.map(Destination.resourceIdentifier(_:)))
	}

	init(data: [ResourceIdentifier]) {
		self.data = data
	}
}

extension RelationshipMany: ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = Destination.ID

	public init(arrayLiteral elements: ArrayLiteralElement...) {
		self.init(identifiers: elements)
	}
}
