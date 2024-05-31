import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct ResourceAttributeMacro: AccessorMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		if let key = node.firstArgumentStringLiteralSegment {
			guard !key.content.text.isEmpty else {
				throw DiagnosticsError(
					syntax: node,
					message:
						"'@ResourceAttribute' requires a non-empty string literal containing the key or 'nil'",
					id: .missingKey
				)
			}
		}
		return []
	}
}
