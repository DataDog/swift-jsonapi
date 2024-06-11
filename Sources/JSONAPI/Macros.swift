@attached(
	extension,
	conformances: ResourceIdentifiable, ResourceDefinitionProviding, ResourceLinkageProviding, Codable,
	names: named(ID), named(Definition), named(BodyDefinition), named(Wrapped), named(Body), named(type),
	named(init(from:)), named(encode(to:))
)
public macro ResourceWrapper(type: String) = #externalMacro(module: "JSONAPIMacros", type: "ResourceWrapperMacro")

@attached(accessor, names: named(willSet))
public macro ResourceAttribute(key: String? = nil) =
	#externalMacro(
		module: "JSONAPIMacros",
		type: "ResourceAttributeMacro"
	)

@attached(accessor, names: named(willSet))
public macro ResourceRelationship(key: String? = nil) =
	#externalMacro(
		module: "JSONAPIMacros",
		type: "ResourceRelationshipMacro"
	)

@attached(
	extension,
	conformances: ResourceIdentifiable, ResourceLinkageProviding, Codable,
	names: named(type), named(id), named(ID), named(resourceIdentifier), named(init(from:)), named(encode(to:))
)
public macro ResourceUnion() = #externalMacro(module: "JSONAPIMacros", type: "ResourceUnionMacro")
