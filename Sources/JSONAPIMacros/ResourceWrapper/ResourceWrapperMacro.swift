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
			try .makeFieldSetExtension(
				attachedTo: declaration,
				providingExtensionsOf: type,
				resourceType: resourceType.content.text
			)
			// TODO: ResourceIdentifiable extension
			// TODO: Codable
		]
	}
}

extension ExtensionDeclSyntax {
	fileprivate static func makeFieldSetExtension(
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		resourceType: String
	) throws -> ExtensionDeclSyntax {
		let modifiers = DeclModifierListSyntax {
			if let publicModifier = declaration.publicModifier {
				publicModifier
			}
		}
		let inheritedTypeList = InheritedTypeListSyntax.makeFieldSetAssociatedTypesInheritedTypeList(
			attachedTo: declaration
		)
		let resourceAttributes = declaration.definedVariables.filter(\.hasResourceAttributeMacro)
		let resourceRelationships = declaration.definedVariables.filter(\.hasResourceRelationshipMacro)

		let members = try MemberBlockItemListSyntax {
			try StructDeclSyntax.makeFieldSet(
				modifiers: modifiers,
				inheritedTypeList: inheritedTypeList,
				resourceAttributes: resourceAttributes,
				resourceRelationships: resourceRelationships,
				resourceType: resourceType
			)
			try StructDeclSyntax.makeUpdateFieldSet(
				modifiers: modifiers,
				inheritedTypeList: inheritedTypeList,
				resourceAttributes: resourceAttributes,
				resourceRelationships: resourceRelationships
			)
			DeclSyntax("\(modifiers)typealias Primitive = Resource<String, FieldSet>")
			DeclSyntax("\(modifiers)typealias Update = ResourceUpdate<String, UpdateFieldSet>")
		}

		return try ExtensionDeclSyntax(
			"""
			\(declaration.attributes.availability ?? [])
			extension \(type)\(MemberBlockSyntax(members: members))
			"""
		)
	}
}

extension StructDeclSyntax {
	fileprivate static func makeFieldSet(
		modifiers: DeclModifierListSyntax,
		inheritedTypeList: InheritedTypeListSyntax,
		resourceAttributes: [VariableDeclSyntax],
		resourceRelationships: [VariableDeclSyntax],
		resourceType: String
	) throws -> StructDeclSyntax {
		try StructDeclSyntax("\(modifiers)struct FieldSet: ResourceFieldSet") {
			if !resourceAttributes.isEmpty {
				try StructDeclSyntax.makeFieldSetAttributes(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceAttributes: resourceAttributes
				)
			}
			if !resourceRelationships.isEmpty {
				try StructDeclSyntax.makeFieldSetRelationships(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceRelationships: resourceRelationships
				)
			}
			DeclSyntax("\(modifiers)static let resourceType = \"\(raw: resourceType)\"")
		}
	}

	fileprivate static func makeUpdateFieldSet(
		modifiers: DeclModifierListSyntax,
		inheritedTypeList: InheritedTypeListSyntax,
		resourceAttributes: [VariableDeclSyntax],
		resourceRelationships: [VariableDeclSyntax]
	) throws -> StructDeclSyntax {
		try StructDeclSyntax("\(modifiers)struct UpdateFieldSet: ResourceFieldSet") {
			if !resourceAttributes.isEmpty {
				try StructDeclSyntax.makeFieldSetAttributes(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceAttributes: resourceAttributes,
					typeKeyPath: \.type?.optional
				)
			}
			if !resourceRelationships.isEmpty {
				try StructDeclSyntax.makeFieldSetRelationships(
					modifiers: modifiers,
					inheritedTypeList: inheritedTypeList,
					resourceRelationships: resourceRelationships,
					typeKeyPath: \.resourceLinkageType
				)
			}
			DeclSyntax("\(modifiers)static let resourceType = FieldSet.resourceType")
		}
	}

	fileprivate static func makeFieldSetAttributes(
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
			}
		}
	}

	fileprivate static func makeFieldSetRelationships(
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
	fileprivate static func makeFieldSetAssociatedTypesInheritedTypeList(
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
			return TypeSyntax("RelationshipOptional<\(resourceType)>")
		} else if resourceType.isArray {
			return TypeSyntax("RelationshipMany<\(resourceType)>")
		} else {
			return TypeSyntax("RelationshipOne<\(resourceType)>")
		}
	}

	fileprivate var resourceLinkageType: TypeSyntax? {
		guard let resourceType = self.isOptional ? self.optionalWrappedType : self.type else {
			return nil
		}
		if resourceType.isArray {
			return TypeSyntax("ResourceLinkageMany").optional
		} else {
			return TypeSyntax("ResourceLinkageOne").optional
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
