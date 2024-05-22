import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CodableResourceUnionMacro: ExtensionMacro {
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
				message: "'@CodableResourceUnion' can only be applied to enum types",
				id: .invalidApplication
			)
		}

		let enumCaseElements = declaration.enumCaseElements

		for enumCaseElement in enumCaseElements {
			if enumCaseElement.parameterCount != 1 {
				throw DiagnosticsError(
					syntax: enumCaseElement,
					message:
						"'@CodableResourceUnion' enum cases are expected to have 1 associated '@CodableResource' type",
					id: .invalidCase
				)
			}
			if enumCaseElement.firstParameterName != nil {
				throw DiagnosticsError(
					syntax: enumCaseElement,
					message: "'@CodableResourceUnion' enum cases are expected to have no parameter name",
					id: .invalidCase
				)
			}
		}

		let extensionMembers = extensionMembers(
			modifier: declaration.publicModifier,
			enumCaseElements: enumCaseElements
		)
		let qualifiedConformanceName = CodableResourceMacro.qualifiedConformanceName

		let extensionDecl = DeclSyntax(
			"""
			\(declaration.attributes.availability)
			extension \(raw: type.trimmedDescription): \(raw: qualifiedConformanceName) {\(extensionMembers)}
			"""
		)
		.cast(ExtensionDeclSyntax.self)

		return [extensionDecl]
	}
}

extension CodableResourceUnionMacro {
	static func extensionMembers(
		modifier: DeclModifierSyntax?,
		enumCaseElements: [EnumCaseElementSyntax]
	) -> DeclSyntax {
		return """
			\(typeComputedProperty(modifier: modifier, enumCaseElements: enumCaseElements))\
			\(idComputedProperty(modifier: modifier, enumCaseElements: enumCaseElements))\
			\(initializer(modifier: modifier, enumCaseElements: enumCaseElements))\
			\(encodeMethod(modifier: modifier, enumCaseElements: enumCaseElements))
			"""
	}

	private static func typeComputedProperty(
		modifier: DeclModifierSyntax?,
		enumCaseElements: [EnumCaseElementSyntax]
	) -> DeclSyntax {
		let switchSyntax = SwitchExprSyntax(subject: ExprSyntax("self")) {
			for enumCaseElement in enumCaseElements {
				SwitchCaseSyntax("case .\(enumCaseElement.name)(let value):") {
					ExprSyntax("return value.type")
				}
			}
		}

		return "\(modifier)var type: String { \(switchSyntax.formatted()) }"
	}

	private static func idComputedProperty(
		modifier: DeclModifierSyntax?,
		enumCaseElements: [EnumCaseElementSyntax]
	) -> DeclSyntax {
		let switchSyntax = SwitchExprSyntax(subject: ExprSyntax("self")) {
			for enumCaseElement in enumCaseElements {
				SwitchCaseSyntax("case .\(enumCaseElement.name)(let value):") {
					ExprSyntax("return String(describing: value.id)")
				}
			}
		}.formatted()

		return "\(modifier)var id: String { \(switchSyntax) }"
	}

	private static func initializer(
		modifier: DeclModifierSyntax?,
		enumCaseElements: [EnumCaseElementSyntax]
	) -> DeclSyntax {
		let switchSyntax = SwitchExprSyntax(subject: ExprSyntax("type")) {
			for enumCaseElement in enumCaseElements {
				SwitchCaseSyntax("case \(enumCaseElement.firstParameterType).resourceType:") {
					ExprSyntax(
						"self = try .\(enumCaseElement.name)(\(enumCaseElement.firstParameterType)(from: decoder))"
					)
				}
			}
			SwitchCaseSyntax("default:") {
				ExprSyntax(
					"""
					throw DecodingError.typeMismatch(
						Self.self,
						.init(
							codingPath: [ResourceCodingKeys.type],
							debugDescription: "Resource type '\\(type)' not found in union."
						)
					)
					"""
				)
			}
		}.formatted()
		let body = DeclSyntax(
			"""
			let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			let type = try container.decode(String.self, forKey: .type)
			\(switchSyntax)
			"""
		)
		return "\(modifier)init(from decoder: any Decoder) throws {\(body)}"
	}

	private static func encodeMethod(
		modifier: DeclModifierSyntax?,
		enumCaseElements: [EnumCaseElementSyntax]
	) -> DeclSyntax {
		let body = SwitchExprSyntax(subject: ExprSyntax("self")) {
			for enumCaseElement in enumCaseElements {
				SwitchCaseSyntax("case .\(enumCaseElement.name)(let value):") {
					ExprSyntax("try value.encode(to: encoder)")
				}
			}
		}.formatted()
		return "\(modifier)func encode(to encoder: any Encoder) throws {\(body)}"
	}
}
