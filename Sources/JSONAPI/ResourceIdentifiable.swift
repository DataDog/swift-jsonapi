import Foundation

public protocol ResourceIdentifiable {
	associatedtype ID: Hashable & CustomStringConvertible

	var type: String { get }
	var id: ID { get }
}
