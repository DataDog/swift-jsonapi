import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ResourceWrapperMacro: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		guard declaration.isStruct else {
			throw DiagnosticsError(
				syntax: node,
				message: "'@ResourceWrapper' can only be applied to struct types",
				id: .invalidApplication
			)
		}

		guard
			let resourceType = node.firstArgumentStringLiteralSegment,
			!resourceType.content.text.isEmpty
		else {
			throw DiagnosticsError(
				syntax: node,
				message: """
					'@ResourceWrapper' requires a non-empty string literal containing the type of the resource
					""",
				id: .missingResourceType
			)
		}

		return [
			try .makeDefinitionExtension(
				attachedTo: declaration,
				providingExtensionsOf: type,
				resourceType: resourceType.content.text
			),
			try .makeResourceIdentifiableExtension(attachedTo: declaration, providingExtensionsOf: type),
			try .makeCodableExtension(attachedTo: declaration, providingExtensionsOf: type),
		]
	}
}

extension ExtensionDeclSyntax {
	fileprivate static func makeDefinitionExtension(
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		resourceType: String
	) throws -> ExtensionDeclSyntax {
		let modifiers = DeclModifierListSyntax {
			if let publicModifier = declaration.publicModifier {
				publicModifier
			}
		}
		let inheritedTypeList = InheritedTypeListSyntax.makeDefinitionAssociatedTypesInheritedTypeList(
			attachedTo: declaration
		)
		let resourceAttributes = declaration.definedVariables.filter(\.hasResourceAttributeMacro)
		let resourceRelationships = declaration.definedVariables.filter(\.hasResourceRelationshipMacro)

		guard let identifier = declaration.definedVariables.first(where: \.isIdentifier) else {
			throw DiagnosticsError(
				syntax: declaration,
				message: "'@ResourceWrapper' requires a valid 'id' property.",
				id: .missingResourceType
			)
		}

		let members = try MemberBlockItemListSyntax {
			try StructDeclSyntax.makeDefinition(
				modifiers: modifiers,
				inheritedTypeList: inheritedTypeList,
				resourceAttributes: resourceAttributes,
				resourceRelationships: resourceRelationships,
				resourceType: resourceType
			)
			try StructDeclSyntax.makeUpdateDefinition(
				modifiers: modifiers,
				inheritedTypeList: inheritedTypeList,
				resourceAttributes: resourceAttributes,
				resourceRelationships: resourceRelationships
			)
			DeclSyntax("\(modifiers)typealias Wrapped = JSONAPI.Resource<\(identifier.type), Definition>")
			DeclSyntax("\(modifiers)typealias Update = JSONAPI.ResourceUpdate<\(identifier.type), UpdateDefinition>")
		}

		return try ExtensionDeclSyntax(
			"""
			\(declaration.attributes.availability)
			extension \(type)\(MemberBlockSyntax(members: members))
			"""
		)
	}

	fileprivate static func makeResourceIdentifiableExtension(
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol
	) throws -> ExtensionDeclSyntax {
		let modifiers = DeclModifierListSyntax {
			if let publicModifier = declaration.publicModifier {
				publicModifier
			}
		}
		let members = MemberBlockItemListSyntax {
			DeclSyntax("\(modifiers)var type: String { Definition.resourceType }")
		}

		return try ExtensionDeclSyntax(
			"""
			\(declaration.attributes.availability)
			extension \(type): JSONAPI.ResourceIdentifiable\(MemberBlockSyntax(members: members))
			"""
		)
	}

	fileprivate static func makeCodableExtension(
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol
	) throws -> ExtensionDeclSyntax {
		let modifiers = DeclModifierListSyntax {
			if let publicModifier = declaration.publicModifier {
				publicModifier
			}
		}
		let resourceAttributes = declaration.definedVariables.filter(\.hasResourceAttributeMacro)
		let resourceRelationships = declaration.definedVariables.filter(\.hasResourceRelationshipMacro)
		let members = try MemberBlockItemListSyntax {
			try InitializerDeclSyntax("\(modifiers)init(from decoder: any Decoder) throws") {
				StmtSyntax("let wrapped = try Wrapped(from: decoder)")
				StmtSyntax("self.id = wrapped.id")
					.with(\.trailingTrivia, .newline)
				for resourceAttribute in resourceAttributes {
					StmtSyntax("self.\(resourceAttribute.identifier) = wrapped.\(resourceAttribute.identifier)")
						.with(\.trailingTrivia, .newline)
				}
				for resourceRelationship in resourceRelationships {
					StmtSyntax(
						"""
						self.\(resourceRelationship.identifier) = \
						wrapped.\(resourceRelationship.identifier).\(resourceRelationship.relationshipResource)
						"""
					).with(\.trailingTrivia, .newline)
				}
			}

			try FunctionDeclSyntax("\(modifiers)func encode(to encoder: any Encoder) throws") {
				if !resourceAttributes.isEmpty {
					StmtSyntax(
						"let attributes = \(FunctionCallExprSyntax.makeWrappedAttributes(resourceAttributes))"
					)
				}
				if !resourceRelationships.isEmpty {
					StmtSyntax(
						"let relationships = \(FunctionCallExprSyntax.makeWrappedRelationships(resourceRelationships))"
					)
				}
				StmtSyntax(
					"let wrapped = \(FunctionCallExprSyntax.makeWrapped(resourceAttributes, resourceRelationships))"
				)
				StmtSyntax("try wrapped.encode(to: encoder)")
			}
		}

		return try ExtensionDeclSyntax(
			"""
			\(declaration.attributes.availability)
			extension \(type): Codable\(MemberBlockSyntax(members: members))
			"""
		)
	}
}

extension StructDeclSyntax {
	fileprivate static func makeDefinition(
		modifiers: DeclModifierListSyntax,
		inheritedTypeList: InheritedTypeListSyntax,
		resourceAttributes: [VariableDeclSyntax],
		resourceRelationships: [VariableDeclSyntax],
		resourceType: String
	) throws -> StructDeclSyntax {
		try StructDeclSyntax("\(modifiers)struct Definition: JSONAPI.ResourceDefinition") {
			if !resourceAttributes.isEmpty {
				try StructDeclSyntax.makeDefinitionAttributes(
					arrayAttributes: AttributeListSyntax {
						AttributeSyntax("@DefaultEmpty")
					},
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceAttributes: resourceAttributes
				)
			}
			if !resourceRelationships.isEmpty {
				try StructDeclSyntax.makeDefinitionRelationships(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceRelationships: resourceRelationships
				)
			}
			DeclSyntax("\(modifiers)static let resourceType = \"\(raw: resourceType)\"")
		}
	}

	fileprivate static func makeUpdateDefinition(
		modifiers: DeclModifierListSyntax,
		inheritedTypeList: InheritedTypeListSyntax,
		resourceAttributes: [VariableDeclSyntax],
		resourceRelationships: [VariableDeclSyntax]
	) throws -> StructDeclSyntax {
		try StructDeclSyntax("\(modifiers)struct UpdateDefinition: JSONAPI.ResourceDefinition") {
			if !resourceAttributes.isEmpty {
				try StructDeclSyntax.makeDefinitionAttributes(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceAttributes: resourceAttributes,
					typeKeyPath: \.type?.optionalType
				)
			}
			if !resourceRelationships.isEmpty {
				try StructDeclSyntax.makeDefinitionRelationships(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceRelationships: resourceRelationships,
					typeKeyPath: \.rawRelationshipType
				)
			}
			DeclSyntax("\(modifiers)static let resourceType = Definition.resourceType")
		}
	}

	fileprivate static func makeDefinitionAttributes(
		arrayAttributes: AttributeListSyntax = [],
		modifiers: DeclModifierListSyntax,
		inheritedTypeList: InheritedTypeListSyntax,
		resourceAttributes: [VariableDeclSyntax],
		typeKeyPath: KeyPath<VariableDeclSyntax, TypeSyntax?> = \.type
	) throws -> StructDeclSyntax {
		try StructDeclSyntax("\(modifiers)struct Attributes:\(inheritedTypeList)") {
			if resourceAttributes.containsResourceAttributeKeys {
				DeclSyntax.makeCodingKeys(for: resourceAttributes, rawValueKeyPath: \.resourceAttributeKey)
			}

			for resourceAttribute in resourceAttributes {
				VariableDeclSyntax(
					attributes: resourceAttribute.type?.isArray == true ? arrayAttributes : [],
					modifiers: resourceAttribute.modifiers,
					bindingSpecifier: resourceAttribute.bindingSpecifier
				) {
					if let identifier = resourceAttribute.identifier,
						let type = resourceAttribute[keyPath: typeKeyPath]
					{
						PatternBindingSyntax(
							pattern: PatternSyntax("\(identifier)"),
							typeAnnotation: TypeAnnotationSyntax(type: type)
						)
					}
				}
				.with(\.trailingTrivia, .newline)
			}
		}
	}

	fileprivate static func makeDefinitionRelationships(
		modifiers: DeclModifierListSyntax,
		inheritedTypeList: InheritedTypeListSyntax,
		resourceRelationships: [VariableDeclSyntax],
		typeKeyPath: KeyPath<VariableDeclSyntax, TypeSyntax?> = \.relationshipType
	) throws -> StructDeclSyntax {
		try StructDeclSyntax("\(modifiers)struct Relationships:\(inheritedTypeList)") {
			if resourceRelationships.containsResourceRelationshipKeys {
				DeclSyntax.makeCodingKeys(for: resourceRelationships, rawValueKeyPath: \.resourceRelationshipKey)
			}

			for resourceRelationship in resourceRelationships {
				VariableDeclSyntax(
					modifiers: resourceRelationship.modifiers,
					bindingSpecifier: resourceRelationship.bindingSpecifier
				) {
					if let identifier = resourceRelationship.identifier,
						let type = resourceRelationship[keyPath: typeKeyPath]
					{
						PatternBindingSyntax(
							pattern: PatternSyntax("\(identifier)"),
							typeAnnotation: TypeAnnotationSyntax(type: type)
						)
					}
				}
			}
		}
	}
}

extension FunctionCallExprSyntax {
	fileprivate static func makeWrappedAttributes(
		_ resourceAttributes: [VariableDeclSyntax]
	) -> FunctionCallExprSyntax {
		FunctionCallExprSyntax(callee: ExprSyntax("Wrapped.Attributes")) {
			for resourceAttribute in resourceAttributes {
				LabeledExprSyntax(
					label: resourceAttribute.identifier,
					colon: .colonToken(trailingTrivia: .space),
					expression: ExprSyntax("self.\(resourceAttribute.identifier)")
				)
			}
		}
	}

	fileprivate static func makeWrappedRelationships(
		_ resourceRelationships: [VariableDeclSyntax]
	) -> FunctionCallExprSyntax {
		FunctionCallExprSyntax(callee: ExprSyntax("Wrapped.Relationships")) {
			for resourceRelationship in resourceRelationships {
				LabeledExprSyntax(
					label: resourceRelationship.identifier,
					colon: .colonToken(trailingTrivia: .space),
					expression: ExprSyntax(
						".init(self.\(resourceRelationship.identifier))"
					)
				)
			}
		}
	}

	fileprivate static func makeWrapped(
		_ resourceAttributes: [VariableDeclSyntax],
		_ resourceRelationships: [VariableDeclSyntax]
	) -> FunctionCallExprSyntax {
		FunctionCallExprSyntax(callee: ExprSyntax("Wrapped")) {
			LabeledExprSyntax(label: "id", expression: ExprSyntax("self.id"))
			if !resourceAttributes.isEmpty {
				LabeledExprSyntax(label: "attributes", expression: ExprSyntax("attributes"))
			}
			if !resourceRelationships.isEmpty {
				LabeledExprSyntax(label: "relationships", expression: ExprSyntax("relationships"))
			}
		}
	}
}

extension DeclSyntax {
	fileprivate static func makeCodingKeys(
		for variables: [VariableDeclSyntax],
		rawValueKeyPath: KeyPath<VariableDeclSyntax, StringSegmentSyntax?>
	) -> DeclSyntax {
		let syntax = EnumDeclSyntax(
			modifiers: DeclModifierListSyntax {
				DeclModifierSyntax(name: .keyword(.private))
			},
			name: "CodingKeys",
			inheritanceClause: InheritanceClauseSyntax {
				InheritedTypeSyntax(type: TypeSyntax("String"))
				InheritedTypeSyntax(type: TypeSyntax("CodingKey"))
			}
		) {
			for variable in variables {
				MemberBlockItemSyntax(
					decl: EnumCaseDeclSyntax {
						EnumCaseElementSyntax(
							name: variable.identifier ?? "unknown",
							rawValue: variable[keyPath: rawValueKeyPath].map {
								InitializerClauseSyntax(value: StringLiteralExprSyntax(content: "\($0)"))
							}
						)
					}
				)
			}
		}.formatted()

		return "\(syntax)"
	}
}

extension InheritedTypeListSyntax {
	fileprivate static func makeDefinitionAssociatedTypesInheritedTypeList(
		attachedTo declaration: some DeclGroupSyntax
	) -> InheritedTypeListSyntax {
		let inheritedTypes = [
			declaration.conformsToEquatable
				? InheritedTypeSyntax(type: TypeSyntax("Equatable"), trailingComma: .commaToken())
				: nil,
			InheritedTypeSyntax(type: TypeSyntax("Codable")),
		].compactMap { $0 }
		return InheritedTypeListSyntax(inheritedTypes)
	}
}

extension DeclGroupSyntax {
	fileprivate var conformsToEquatable: Bool {
		guard let inheritanceClause else {
			return false
		}

		return inheritanceClause.inheritedTypes.contains {
			$0.type.as(IdentifierTypeSyntax.self)?.name.text == "Equatable"
		}
	}
}

extension VariableDeclSyntax {
	fileprivate var hasResourceAttributeMacro: Bool {
		self.hasMacroApplication("ResourceAttribute")
	}

	fileprivate var hasResourceRelationshipMacro: Bool {
		self.hasMacroApplication("ResourceRelationship")
	}

	fileprivate var isIdentifier: Bool {
		self.identifier?.text == "id"
	}

	fileprivate var resourceAttributeKey: StringSegmentSyntax? {
		self.attribute(named: "ResourceAttribute")?.firstArgumentStringLiteralSegment
	}

	fileprivate var resourceRelationshipKey: StringSegmentSyntax? {
		self.attribute(named: "ResourceRelationship")?.firstArgumentStringLiteralSegment
	}

	fileprivate var relationshipType: TypeSyntax? {
		guard let resourceType = self.isOptional ? self.optionalWrappedType : self.type else {
			return nil
		}
		if self.isOptional, !resourceType.isArray {
			return TypeSyntax("JSONAPI.InlineRelationshipOptional<\(resourceType)>")
		} else if resourceType.isArray {
			return TypeSyntax("JSONAPI.InlineRelationshipMany<\(resourceType.arrayElementType)>")
		} else {
			return TypeSyntax("JSONAPI.InlineRelationshipOne<\(resourceType)>")
		}
	}

	fileprivate var relationshipResource: TokenSyntax? {
		guard let resourceType = self.isOptional ? self.optionalWrappedType : self.type else {
			return nil
		}
		return resourceType.isArray ? "resources" : "resource"
	}

	fileprivate var rawRelationshipType: TypeSyntax? {
		guard let resourceType = self.isOptional ? self.optionalWrappedType : self.type else {
			return nil
		}
		if resourceType.isArray {
			return TypeSyntax("JSONAPI.RawRelationshipMany").optionalType
		} else {
			return TypeSyntax("JSONAPI.RawRelationshipOne").optionalType
		}
	}
}

extension Array where Element == VariableDeclSyntax {
	fileprivate var containsResourceAttributeKeys: Bool {
		self.contains { $0.resourceAttributeKey != nil }
	}

	fileprivate var containsResourceRelationshipKeys: Bool {
		self.contains { $0.resourceRelationshipKey != nil }
	}
}
