import Foundation

/// A type that provides a JSON:API resource definition.
public protocol ResourceDefinitionProviding {
	associatedtype Definition: ResourceDefinition
}
