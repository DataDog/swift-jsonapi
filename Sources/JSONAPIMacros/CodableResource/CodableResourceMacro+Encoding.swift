import SwiftSyntax
import SwiftSyntaxBuilder

extension CodableResourceMacro {
  static func encodeMethod(
    modifier: DeclModifierSyntax?,
    attributes: [VariableDeclSyntax],
    relationships: [VariableDeclSyntax]
  ) -> DeclSyntax {
    return """
      \(modifier)func encode(to encoder: any Encoder) throws {
          \(encodeMethodBody(attributes: attributes, relationships: relationships))
      }
      """
  }

  private static func encodeMethodBody(
    attributes: [VariableDeclSyntax],
    relationships: [VariableDeclSyntax]
  ) -> DeclSyntax {
    return """
      var container = encoder.container(keyedBy: ResourceCodingKeys.self)
      try container.encode(Self.\(raw: typeVariableIdentifier), forKey: .\(raw: typeVariableIdentifier))
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

    return """
      \(raw: output)
      """
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
      guard let includedResourceEncoder = encoder.includedResourceEncoder else {
        throw DocumentEncodingError.includedResourceEncodingNotEnabled
      }
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

    return """
      \(raw: output)
      """
  }

  private static func encodeRelationship(_ variable: VariableDeclSyntax) -> DeclSyntax {
    var encodeModelAndResource: DeclSyntax = """
      \(encodeRelationshipModel(variable))
      \(encodeIncludedResource(variable))
      """

    if variable.isOptional {
      encodeModelAndResource = optionalBinding(variable, body: encodeModelAndResource)
    }

    return encodeModelAndResource
  }

  private static func encodeRelationshipModel(_ variable: VariableDeclSyntax) -> DeclSyntax {
    let type = variable.isOptional ? variable.optionalWrappedType : variable.type
    let relationshipType = (type?.isArray ?? false) ? "RelationshipToMany" : "RelationshipToOne"
    let parameterLabel = (type?.isArray ?? false) ? "resources" : "resource"

    return """
      try relationshipsContainer.encode\
      (\(raw: relationshipType)(\(raw: parameterLabel): \(variable.identifier)), forKey: .\(variable.identifier))
      """
  }

  private static func encodeIncludedResource(_ variable: VariableDeclSyntax) -> DeclSyntax {
    """
    try includedResourceEncoder.encode(\(variable.identifier))
    """
  }

  private static func optionalBinding(
    _ variable: VariableDeclSyntax,
    body: DeclSyntax
  ) -> DeclSyntax {
    """
    if let \(variable.identifier) {
      \(body)
    }
    """
  }
}
