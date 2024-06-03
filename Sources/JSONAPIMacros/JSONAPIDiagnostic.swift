import SwiftDiagnostics
import SwiftSyntax

struct JSONAPIDiagnostic: DiagnosticMessage {
	enum ID: String {
		case invalidApplication = "invalid type"
		case missingResourceType = "missing resource type"
		case missingIdProperty = "missing id property"
		case missingKey = "missing key"
		case invalidCase = "invalid case"
	}

	var message: String
	var diagnosticID: MessageID
	var severity: DiagnosticSeverity

	init(
		message: String, diagnosticID: SwiftDiagnostics.MessageID,
		severity: SwiftDiagnostics.DiagnosticSeverity = .error
	) {
		self.message = message
		self.diagnosticID = diagnosticID
		self.severity = severity
	}

	init(
		message: String,
		domain: String,
		id: ID,
		severity: SwiftDiagnostics.DiagnosticSeverity = .error
	) {
		self.message = message
		self.diagnosticID = MessageID(domain: domain, id: id.rawValue)
		self.severity = severity
	}
}

extension DiagnosticsError {
	init<S: SyntaxProtocol>(
		syntax: S,
		message: String,
		domain: String = "JSONAPI",
		id: JSONAPIDiagnostic.ID,
		severity: SwiftDiagnostics.DiagnosticSeverity = .error
	) {
		self.init(
			diagnostics: [
				Diagnostic(
					node: Syntax(syntax),
					message: JSONAPIDiagnostic(
						message: message, domain: domain, id: id, severity: severity)
				)
			]
		)
	}
}
