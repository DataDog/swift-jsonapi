@attached(member, names: named(type), named(id))
@attached(
	extension,
	conformances: ResourceType, CodableResource,
	names:
		named(resourceType),
	named(ResourceAttributeCodingKeys),
	named(ResourceRelationshipCodingKeys),
	named(init(from:)),
	named(encode(to:))
)
public macro CodableResource(type: String) = #externalMacro(module: "JSONAPIMacros", type: "CodableResourceMacro")

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
	conformances: CodableResource,
	names: named(type), named(id), named(init(from:)), named(encode(to:))
)
public macro CodableResourceUnion() = #externalMacro(module: "JSONAPIMacros", type: "CodableResourceUnionMacro")
