// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import SwiftSyntax
import SwiftSyntaxBuilder

extension SyntaxStringInterpolation {
	mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
		if let node = node {
			appendInterpolation(node)
		}
	}
}

extension DeclGroupSyntax {
	var publicModifier: DeclModifierSyntax? {
		self.modifiers.first { modifier in
			modifier.tokens(viewMode: .all).contains { token in
				token.tokenKind == .keyword(.public)
			}
		}
	}

	var enumCaseElements: [EnumCaseElementSyntax] {
		memberBlock.members.compactMap { member in
			member.decl.as(EnumCaseDeclSyntax.self)
		}.flatMap(\.elements)
	}
}

extension VariableDeclSyntax {
	var isArray: Bool {
		self.type?.isArray ?? false
	}

	var isOptional: Bool {
		self.type?.isOptional ?? false
	}

	var optionalWrappedType: TypeSyntax? {
		self.type?.optionalWrappedType
	}

	func attribute(named name: String) -> AttributeSyntax? {
		for attribute in attributes {
			switch attribute {
			case .attribute(let attr):
				if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [
					.identifier(name)
				] {
					return attr
				}
			default:
				return nil
			}
		}
		return nil
	}
}

extension TypeSyntax {
	var isArray: Bool {
		// Check for shorthand array syntax ([Type])
		if self.is(ArrayTypeSyntax.self) {
			return true
		}

		// Check for Array<Element> syntax
		if let identifierType = self.as(IdentifierTypeSyntax.self),
			identifierType.name.text == "Array"
		{
			return true
		}

		return false
	}

	var arrayElementType: TypeSyntax? {
		if let arrayType = self.as(ArrayTypeSyntax.self) {
			return arrayType.element
		}

		if let identifierType = self.as(IdentifierTypeSyntax.self),
			identifierType.name.text == "Array",
			let genericArgumentClause = identifierType.genericArgumentClause,
			let firstArgument = genericArgumentClause.arguments.first
		{
			return firstArgument.argument
		}

		return nil
	}

	var isOptional: Bool {
		// Check for shorthand optional syntax (Type?)
		if self.is(OptionalTypeSyntax.self) {
			return true
		}

		// Check for Optional<Type> generic type syntax
		if let identifierType = self.as(IdentifierTypeSyntax.self),
			identifierType.name.text == "Optional"
		{
			return true
		}

		return false
	}

	var optionalWrappedType: TypeSyntax? {
		// Check for shorthand optional syntax (Type?)
		if let optionalType = self.as(OptionalTypeSyntax.self) {
			return optionalType.wrappedType
		}

		// Check for Optional<Type> generic type syntax
		if let identifierType = self.as(IdentifierTypeSyntax.self),
			identifierType.name.text == "Optional",
			let genericArgumentClause = identifierType.genericArgumentClause,
			let firstArgument = genericArgumentClause.arguments.first
		{
			return firstArgument.argument
		}

		return nil
	}

	var optionalType: TypeSyntax {
		guard !self.isOptional else {
			return self
		}
		return TypeSyntax(OptionalTypeSyntax(wrappedType: self))
	}
}

extension AttributeSyntax {
	var firstArgument: LabeledExprSyntax? {
		guard case .argumentList(let arguments) = self.arguments else {
			return nil
		}
		return arguments.first
	}

	var firstArgumentStringLiteral: StringLiteralExprSyntax? {
		self.firstArgument?.expression.as(StringLiteralExprSyntax.self)
	}

	var firstArgumentStringLiteralSegment: StringSegmentSyntax? {
		self.firstArgumentStringLiteral?.segments.first?.as(StringSegmentSyntax.self)
	}
}

extension EnumCaseElementSyntax {
	var parameterCount: Int {
		self.parameterClause?.parameters.count ?? 0
	}

	var firstParameterName: TokenSyntax? {
		self.parameterClause?.parameters.first?.firstName
	}

	var firstParameterType: TypeSyntax? {
		self.parameterClause?.parameters.first?.type
	}
}
