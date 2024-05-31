import Foundation

@available(*, deprecated, renamed: "ResourceWrapper")
@attached(
	extension,
	conformances: ResourceIdentifiable, Codable,
	names: named(FieldSet), named(UpdateFieldSet), named(Wrapped), named(Update), named(type), named(init(from:)),
	named(encode(to:))
)
public macro CodableResource(type: String) = #externalMacro(module: "JSONAPIMacros", type: "ResourceWrapperMacro")
