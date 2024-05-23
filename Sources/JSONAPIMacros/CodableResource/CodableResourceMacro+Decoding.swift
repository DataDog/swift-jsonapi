import SwiftSyntax
import SwiftSyntaxBuilder

extension CodableResourceMacro {
	static func decodableInitializer(
		modifier: DeclModifierSyntax?,
		idType: TypeSyntax,
		attributes: [VariableDeclSyntax],
		relationships: [VariableDeclSyntax]
	) -> DeclSyntax {
		let body = decodableInitializerBody(idType: idType, attributes: attributes, relationships: relationships)
		return "\(modifier)init(from decoder: any Decoder) throws {\(body)}"
	}

	private static func decodableInitializerBody(
		idType: TypeSyntax,
		attributes: [VariableDeclSyntax],
		relationships: [VariableDeclSyntax]
	) -> DeclSyntax {
		return """
			let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
			try container.checkResourceType(Self.self)
			self.\(raw: idVariableIdentifier) = try container.decode(\(idType).self, forKey: .\(raw: idVariableIdentifier))
			\(attributesDecodingContainer(attributes))\
			\(decodeAttributes(attributes))\
			\(includedResourceDecoder(relationships))\
			\(relationshipDecodingContainer(relationships))\
			\(decodeRelationships(relationships))
			"""
	}

	private static func attributesDecodingContainer(
		_ variables: [VariableDeclSyntax]
	) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		return """
			let attributesContainer = try container.nestedContainer\
			(keyedBy: \(raw: resourceAttributeCodingKeysName).self, forKey: .attributes)
			"""
	}

	private static func decodeAttributes(_ variables: [VariableDeclSyntax]) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		let output = variables.map { variable in
			decodeAttribute(variable).description
		}
		.joined(separator: "\n")

		return "\(raw: output)"
	}

	private static func decodeAttribute(_ variable: VariableDeclSyntax) -> DeclSyntax {
		let method = variable.isOptional || variable.isArray ? "decodeIfPresent" : "decode"
		let type = variable.isOptional ? variable.optionalWrappedType : variable.type
		let arrayNilCoalesce: DeclSyntax = variable.isArray ? " ?? []" : ""

		return """
			self.\(variable.identifier) = try attributesContainer.\
			\(raw: method)(\(type).self, forKey: .\(variable.identifier))\(arrayNilCoalesce)
			"""
	}

	private static func includedResourceDecoder(_ variables: [VariableDeclSyntax]) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		return """
			guard let includedResourceDecoder = decoder.includedResourceDecoder else {\
			throw DocumentDecodingError.includedResourceDecodingNotEnabled}
			"""
	}

	private static func relationshipDecodingContainer(
		_ variables: [VariableDeclSyntax]
	) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		return """
			let relationshipsContainer = try container.nestedContainer\
			(keyedBy: \(raw: resourceRelationshipCodingKeysName).self, forKey: .relationships)
			"""
	}

	private static func decodeRelationships(_ variables: [VariableDeclSyntax]) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		let output = variables.map { variable in
			decodeRelationship(variable).description
		}
		.joined(separator: "\n")

		return "\(raw: output)"
	}

	private static func decodeRelationship(_ variable: VariableDeclSyntax) -> DeclSyntax {
		"\(decodeRelationshipModel(variable))\(decodeIncluded(variable))"
	}

	private static func decodeRelationshipModel(_ variable: VariableDeclSyntax) -> DeclSyntax {
		let method = variable.isOptional ? "decodeIfPresent" : "decode"
		let type = variable.isOptional ? variable.optionalWrappedType : variable.type
		let isArray = (type?.isArray ?? false)
		let relationshipType =
			if variable.isOptional, !isArray {
				"OptionalRelationshipToOne"
			} else {
				isArray ? "RelationshipToMany" : "RelationshipToOne"
			}

		return """
			let \(variable.identifier)Relationship = try relationshipsContainer.\
			\(raw: method)(\(raw: relationshipType).self, forKey: .\(variable.identifier))
			"""
	}

	private static func decodeIncluded(_ variable: VariableDeclSyntax) -> DeclSyntax {
		let method = variable.isOptional ? "decodeIfPresent" : "decode"
		let type = variable.isOptional ? variable.optionalWrappedType : variable.type

		return """
			self.\(variable.identifier) = try includedResourceDecoder.\(raw: method)\
			(\(type).self, forRelationship: \(variable.identifier)Relationship)
			"""
	}
}
