import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct JSONAPIPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    CodableResourceMacro.self,
    ResourceAttributeMacro.self,
    ResourceRelationshipMacro.self,
  ]
}
