@attached(member, names: named(type), named(id))
@attached(
	extension,
	conformances: CodableResource,
	names:
		named(ResourceAttributeCodingKeys),
	named(ResourceRelationshipCodingKeys),
	named(init(from:)),
	named(encode(to:))
)
public macro CodableResource(type: String) =
	#externalMacro(
		module: "JSONAPIMacros",
		type: "CodableResourceMacro"
	)

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
