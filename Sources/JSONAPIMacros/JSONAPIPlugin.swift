// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

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
