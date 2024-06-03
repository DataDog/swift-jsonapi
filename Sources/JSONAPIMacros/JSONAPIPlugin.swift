import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct JSONAPIPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		ResourceWrapperMacro.self,
		ResourceAttributeMacro.self,
		ResourceRelationshipMacro.self,
		ResourceUnionMacro.self,
	]
}
