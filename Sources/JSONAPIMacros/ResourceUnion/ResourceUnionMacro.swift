import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ResourceUnionMacro: ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		guard declaration.isEnum else {
			throw DiagnosticsError(
				syntax: node,
				message: "'@ResourceUnion' can only be applied to enum types",
				id: .invalidApplication
			)
		}

		for enumCaseElement in declaration.enumCaseElements {
			if enumCaseElement.parameterCount != 1 {
				throw DiagnosticsError(
					syntax: enumCaseElement,
					message:
						"'@ResourceUnion' enum cases are expected to have 1 associated 'ResourceIdentifiable' type",
					id: .invalidCase
				)
			}
			if enumCaseElement.firstParameterName != nil {
				throw DiagnosticsError(
					syntax: enumCaseElement,
					message: "'@ResourceUnion' enum cases are expected to have no parameter name",
					id: .invalidCase
				)
			}
		}

		return [
			try .makeResourceIdentifiableExtension(attachedTo: declaration, providingExtensionsOf: type),
			try .makeCodableExtension(attachedTo: declaration, providingExtensionsOf: type),
		]
	}
}

extension ExtensionDeclSyntax {
	fileprivate static func makeResourceIdentifiableExtension(
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol
	) throws -> ExtensionDeclSyntax {
		let extractType = SwitchExprSyntax(subject: ExprSyntax("self")) {
			for enumCaseElement in declaration.enumCaseElements {
				SwitchCaseSyntax("case .\(enumCaseElement.name)(let value):") {
					ExprSyntax("return value.type")
				}
			}
		}
		let extractId = SwitchExprSyntax(subject: ExprSyntax("self")) {
			for enumCaseElement in declaration.enumCaseElements {
				SwitchCaseSyntax("case .\(enumCaseElement.name)(let value):") {
					ExprSyntax("return String(describing: value.id)")
				}
			}
		}
		let members = MemberBlockItemListSyntax {
			DeclSyntax("\(declaration.publicModifier)var type: String { \(extractType.formatted()) }")
			DeclSyntax("\(declaration.publicModifier)var id: String { \(extractId.formatted()) }")
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
		let decodeValue = SwitchExprSyntax(subject: ExprSyntax("type")) {
			for element in declaration.enumCaseElements {
				SwitchCaseSyntax("case \(element.firstParameterType).Definition.resourceType:") {
					ExprSyntax("self = try .\(element.name)(\(element.firstParameterType)(from: decoder))")
				}
			}
			SwitchCaseSyntax("default:") {
				ExprSyntax("throw JSONAPIDecodingError.unhandledResourceType(Self.self, type)")
			}
		}
		let encodeValue = SwitchExprSyntax(subject: ExprSyntax("self")) {
			for element in declaration.enumCaseElements {
				SwitchCaseSyntax("case .\(element.name)(let value):") {
					ExprSyntax("try value.encode(to: encoder)")
				}
			}
		}
		let members = try MemberBlockItemListSyntax {
			try InitializerDeclSyntax("\(declaration.publicModifier)init(from decoder: any Decoder) throws") {
				StmtSyntax("let container = try decoder.container(keyedBy: ResourceCodingKeys.self)")
				StmtSyntax("let type = try container.decode(String.self, forKey: .type)")
				DeclSyntax("\(decodeValue.formatted())")
			}
			try FunctionDeclSyntax("\(declaration.publicModifier)func encode(to encoder: any Encoder) throws") {
				DeclSyntax("\(encodeValue.formatted())")
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
