import SwiftSyntax
import SwiftSyntaxBuilder

extension CodableResourceMacro {
	static let moduleName = "JSONAPI"
	static let conformanceName = "CodableResource"

	static var qualifiedConformanceName: String {
		"\(moduleName).\(conformanceName)"
	}

	static let typeVariableIdentifier = "type"
	static let idVariableIdentifier = "id"

	static let resourceAttributeMacroName = "ResourceAttribute"
	static let resourceAttributeCodingKeysName = "ResourceAttributeCodingKeys"

	static let resourceRelationshipMacroName = "ResourceRelationship"
	static let resourceRelationshipCodingKeysName = "ResourceRelationshipCodingKeys"

	static func resourceType(modifier: DeclModifierSyntax?, value: StringSegmentSyntax?) -> DeclSyntax? {
		guard let value else {
			return nil
		}

		return """
			\(modifier) static let resourceType = "\(value)"
			"""
	}

	static func type(modifier: DeclModifierSyntax?) -> DeclSyntax {
		"\(modifier)let \(raw: typeVariableIdentifier) = Self.resourceType"
	}

	static func id(modifier: DeclModifierSyntax?) -> DeclSyntax {
		"\(modifier)var \(raw: idVariableIdentifier): String"
	}

	static func codableResourceMembers(
		modifier: DeclModifierSyntax?,
		idType: TypeSyntax,
		attributes: [VariableDeclSyntax],
		relationships: [VariableDeclSyntax]
	) -> DeclSyntax {
		let attributeCodingKeys = codingKeysEnum(
			for: attributes,
			accessorMacro: resourceAttributeMacroName,
			typeName: resourceAttributeCodingKeysName
		)
		let relationshipCodingKeys = codingKeysEnum(
			for: relationships,
			accessorMacro: resourceRelationshipMacroName,
			typeName: resourceRelationshipCodingKeysName
		)
		let decodableInitializer = decodableInitializer(
			modifier: modifier,
			idType: idType,
			attributes: attributes,
			relationships: relationships
		)
		let encodeMethod = encodeMethod(
			modifier: modifier,
			attributes: attributes,
			relationships: relationships
		)

		return """
			\(attributeCodingKeys)
			\(relationshipCodingKeys)
			\(decodableInitializer)
			\(encodeMethod)
			"""
	}

	private static func codingKeysEnum(
		for variables: [VariableDeclSyntax],
		accessorMacro: String,
		typeName: String
	) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		let cases = codingKeysCases(for: variables, accessorMacro: accessorMacro)
		return "private enum \(raw: typeName): String, CodingKey {\(cases)}"
	}

	private static func codingKeysCases(
		for variables: [VariableDeclSyntax],
		accessorMacro: String
	) -> DeclSyntax {
		var cases: [DeclSyntax] = []

		for variable in variables {
			guard
				let macroAttribute = variable.attribute(named: accessorMacro),
				let identifier = variable.identifier
			else {
				continue
			}

			if let key = macroAttribute.firstArgumentStringLiteralSegment {
				cases.append("case \(identifier) = \"\(key)\"")
			} else {
				cases.append("case \(identifier)")
			}
		}

		return "\(raw: cases.map(\.description).joined(separator: "\n"))"
	}
}
