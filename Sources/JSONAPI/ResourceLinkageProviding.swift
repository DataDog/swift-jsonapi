import Foundation

/// A type that provides resource linkage for an identifier type.
public protocol ResourceLinkageProviding {
	associatedtype ID

	static func resourceIdentifier(_ id: ID) -> ResourceIdentifier
}

extension ResourceLinkageProviding where Self: ResourceDefinitionProviding, ID: CustomStringConvertible {
	public static func resourceIdentifier(_ id: ID) -> ResourceIdentifier {
		ResourceIdentifier(type: Definition.resourceType, id: String(describing: id))
	}
}
