@attached(
	extension,
	conformances: ResourceIdentifiable, Codable,
	names: named(FieldSet), named(UpdateFieldSet), named(Wrapped), named(Update), named(type), named(init(from:)),
	named(encode(to:))
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
//
//@attached(
//	extension,
//	conformances: CodableResource,
//	names: named(type), named(id), named(init(from:)), named(encode(to:))
//)
//public macro CodableResourceUnion() = #externalMacro(module: "JSONAPIMacros", type: "CodableResourceUnionMacro")
