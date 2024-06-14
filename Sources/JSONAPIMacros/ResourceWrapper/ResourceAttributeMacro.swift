// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

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
