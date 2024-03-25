import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CodableResourceMacro {
}

extension CodableResourceMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let namedDeclaration = declaration.asProtocol(NamedDeclSyntax.self) else {
      return []
    }

    let codableResourceType = namedDeclaration.name.trimmed

    if declaration.isEnum {
      throw DiagnosticsError(
        syntax: node,
        message:
          "'@CodableResource' cannot be applied to enumeration type \(codableResourceType.text)",
        id: .invalidApplication
      )
    }

    if declaration.isClass {
      throw DiagnosticsError(
        syntax: node,
        message: "'@CodableResource' cannot be applied to class type \(codableResourceType.text)",
        id: .invalidApplication
      )
    }

    if declaration.isActor {
      throw DiagnosticsError(
        syntax: node,
        message: "'@CodableResource' cannot be applied to actor type \(codableResourceType.text)",
        id: .invalidApplication
      )
    }

    guard
      let resourceType = node.firstArgumentStringLiteralSegment,
      !resourceType.content.text.isEmpty
    else {
      throw DiagnosticsError(
        syntax: node,
        message:
          "'@CodableResource' requires a non-empty string literal containing the type of the resource",
        id: .missingResourceType
      )
    }

    var declarations = [DeclSyntax]()

    // Add required properties
    declaration.addIfNeeded(
      self.id(modifier: declaration.publicModifier),
      to: &declarations
    )
    declaration.addIfNeeded(
      self.type(modifier: declaration.publicModifier, value: resourceType),
      to: &declarations
    )

    return declarations
  }
}

extension CodableResourceMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // The user may have already defined an 'id' variable with a tagged type instead of 'String'.
    let idType =
      declaration.definedVariables.first { variable in
        variable.identifier?.text == idVariableIdentifier
      }?.type ?? IdentifierTypeSyntax(name: .identifier("String")).cast(TypeSyntax.self)

    let attributes = declaration.definedVariables.filter { variable in
      variable.hasMacroApplication(resourceAttributeMacroName)
    }

    let relationships = declaration.definedVariables.filter { variable in
      variable.hasMacroApplication(resourceRelationshipMacroName)
    }

    let extensionMembers = extensionMembers(
      modifier: declaration.publicModifier,
      idType: idType,
      attributes: attributes,
      relationships: relationships
    )

    let extensionDecl = DeclSyntax(
      """
      \(declaration.attributes.availability)
      extension \(raw: type.trimmedDescription): \(raw: qualifiedConformanceName) {
        \(extensionMembers)
      }
      """
    )
    .cast(ExtensionDeclSyntax.self)

    return [extensionDecl]
  }
}
