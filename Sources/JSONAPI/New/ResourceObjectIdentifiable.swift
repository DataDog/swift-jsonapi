import Foundation

public protocol ResourceObjectIdentifiable {
	associatedtype ID: Hashable & Codable & CustomStringConvertible

	var type: String { get }
	var id: ID { get }
}
