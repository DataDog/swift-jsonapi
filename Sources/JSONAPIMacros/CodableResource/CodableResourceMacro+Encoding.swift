import SwiftSyntax
import SwiftSyntaxBuilder

extension CodableResourceMacro {
	static func encodeMethod(
		modifier: DeclModifierSyntax?,
		attributes: [VariableDeclSyntax],
		relationships: [VariableDeclSyntax]
	) -> DeclSyntax {
		let body = encodeMethodBody(attributes: attributes, relationships: relationships)
		return "\(modifier)func encode(to encoder: any Encoder) throws {\(body)}"
	}

	private static func encodeMethodBody(
		attributes: [VariableDeclSyntax],
		relationships: [VariableDeclSyntax]
	) -> DeclSyntax {
		return """
			var container = encoder.container(keyedBy: ResourceCodingKeys.self)
			try container.encode(self.\(raw: typeVariableIdentifier), forKey: .\(raw: typeVariableIdentifier))
			try container.encode(self.\(raw: idVariableIdentifier), forKey: .\(raw: idVariableIdentifier))
			\(attributesEncodingContainer(attributes))\
			\(encodeAttributes(attributes))\
			\(includedResourceEncoder(relationships))\
			\(relationshipEncodingContainer(relationships))\
			\(encodeRelationships(relationships))
			"""
	}

	private static func attributesEncodingContainer(
		_ variables: [VariableDeclSyntax]
	) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		return """
			var attributesContainer = container.nestedContainer\
			(keyedBy: \(raw: resourceAttributeCodingKeysName).self, forKey: .attributes)
			"""
	}

	private static func encodeAttributes(_ variables: [VariableDeclSyntax]) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		let output = variables.map { variable in
			encodeAttribute(variable).description
		}
		.joined(separator: "\n")

		return "\(raw: output)"
	}

	private static func encodeAttribute(_ variable: VariableDeclSyntax) -> DeclSyntax {
		let method = variable.isOptional ? "encodeIfPresent" : "encode"

		return """
			try attributesContainer.\(raw: method)(self.\(variable.identifier), forKey: .\(variable.identifier))
			"""
	}

	private static func includedResourceEncoder(_ variables: [VariableDeclSyntax]) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}
		return """
			guard let includedResourceEncoder = encoder.includedResourceEncoder else {\
			fatalError("You must use a 'JSONAPIEncoder' instance to encode a JSON:API resource.")}
			"""
	}

	private static func relationshipEncodingContainer(
		_ variables: [VariableDeclSyntax]
	) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		return """
			var relationshipsContainer = container.nestedContainer\
			(keyedBy: \(raw: resourceRelationshipCodingKeysName).self, forKey: .relationships)
			"""
	}

	private static func encodeRelationships(_ variables: [VariableDeclSyntax]) -> DeclSyntax? {
		guard !variables.isEmpty else {
			return nil
		}

		let output = variables.map { variable in
			encodeRelationship(variable).description
		}
		.joined(separator: "\n")

		return "\(raw: output)"
	}

	private static func encodeRelationship(_ variable: VariableDeclSyntax) -> DeclSyntax {
		"\(encodeRelationshipModel(variable))\(encodeIncludedResource(variable))"
	}

	private static func encodeRelationshipModel(_ variable: VariableDeclSyntax) -> DeclSyntax {
		let method = variable.isOptional ? "encodeIfPresent" : "encode"
		let type = variable.isOptional ? variable.optionalWrappedType : variable.type
		let isArray = (type?.isArray ?? false)
		let relationshipType = isArray ? "RelationshipToMany" : "RelationshipToOne"
		let parameterLabel = isArray ? "resources" : "resource"

		return """
			try relationshipsContainer.\(raw: method)\
			(\(raw: relationshipType)(\(raw: parameterLabel): self.\(variable.identifier)), forKey: .\(variable.identifier))
			"""
	}

	private static func encodeIncludedResource(_ variable: VariableDeclSyntax) -> DeclSyntax {
		let method = variable.isOptional ? "encodeIfPresent" : "encode"
		return "includedResourceEncoder.\(raw: method)(self.\(variable.identifier))"
	}
}
