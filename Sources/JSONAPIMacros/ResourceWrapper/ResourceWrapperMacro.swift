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
			try fieldSetExtension(attachedTo: declaration, providingExtensionsOf: type)
			// TODO: ResourceIdentifiable extension
			// TODO: Codable
		]
	}

	private static func fieldSetExtension(
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol
	) throws -> ExtensionDeclSyntax {
		let resourceAttributes = declaration.definedVariables.filter(\.hasResourceAttributeMacro)
		let resourceRelationships = declaration.definedVariables.filter(\.hasResourceRelationshipMacro)
		let inheritedTypeList = InheritedTypeListSyntax(
			[
				declaration.inheritanceClause?.inheritedTypes.first(where: { $0.type == "Equatable" }),
				InheritedTypeSyntax(type: TypeSyntax("Codable")),
			].compactMap { $0 }
		)

		let members = try MemberBlockItemListSyntax {
			try StructDeclSyntax("\(declaration.publicModifier)struct FieldSet: ResourceFieldSet") {
				if !resourceAttributes.isEmpty {
					try StructDeclSyntax("\(declaration.publicModifier)struct Attributes:\(inheritedTypeList)") {
					}
				}
				if !resourceRelationships.isEmpty {
					try StructDeclSyntax("\(declaration.publicModifier)struct Relationships:\(inheritedTypeList)") {
					}
				}
			}
			try StructDeclSyntax("\(declaration.publicModifier)struct UpdateFieldSet: ResourceFieldSet") {

			}
		}

		return try ExtensionDeclSyntax(
			"""
			\(declaration.attributes.availability ?? [])
			extension \(type)\(MemberBlockSyntax(members: members))
			"""
		)
	}
}

extension VariableDeclSyntax {
	fileprivate var hasResourceAttributeMacro: Bool {
		hasMacroApplication("ResourceAttribute")
	}

	fileprivate var hasResourceRelationshipMacro: Bool {
		hasMacroApplication("ResourceRelationship")
	}
}
