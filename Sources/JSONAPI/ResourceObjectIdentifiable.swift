import Foundation

public protocol ResourceObjectIdentifiable {
	associatedtype ID: Hashable & CustomStringConvertible

	var type: String { get }
	var id: ID { get }
}
