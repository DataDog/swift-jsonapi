import JSONAPIMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class ResourceUnionMacroTests: XCTestCase {
	override func invokeTest() {
		withMacroTesting(
			macros: [ResourceUnionMacro.self]
		) {
			super.invokeTest()
		}
	}

	func testResourceUnionRequiresEnum() {
		assertMacro {
			"""
			@ResourceUnion
			struct Attachment: Equatable {
				var image: Image
				var audio: Audio
			}
			"""
		} diagnostics: {
			"""
			@ResourceUnion
			┬─────────────
			╰─ 🛑 '@ResourceUnion' can only be applied to enum types
			struct Attachment: Equatable {
				var image: Image
				var audio: Audio
			}
			"""
		}
	}

	func testResourceUnionCaseRequiresAssociatedType() {
		assertMacro {
			"""
			@ResourceUnion
			enum Attachment: Equatable {
				case image(Image)
				case audio
			}
			"""
		} diagnostics: {
			"""
			@ResourceUnion
			enum Attachment: Equatable {
				case image(Image)
				case audio
			      ┬────
			      ╰─ 🛑 '@ResourceUnion' enum cases are expected to have 1 associated 'ResourceIdentifiable' type
			}
			"""
		}
	}

	func testResourceUnionCaseRequiresNoParameterName() {
		assertMacro {
			"""
			@ResourceUnion
			enum Attachment: Equatable {
				case image(Image)
				case audio(test: Audio)
			}
			"""
		} diagnostics: {
			"""
			@ResourceUnion
			enum Attachment: Equatable {
				case image(Image)
				case audio(test: Audio)
			      ┬─────────────────
			      ╰─ 🛑 '@ResourceUnion' enum cases are expected to have no parameter name
			}
			"""
		}
	}

	func testResourceUnion() {
		assertMacro {
			"""
			@ResourceUnion
			enum Attachment: Equatable {
				case image(Image)
				case audio(Audio)
			}
			"""
		} expansion: {
			"""
			enum Attachment: Equatable {
				case image(Image)
				case audio(Audio)
			}

			extension Attachment: JSONAPI.ResourceIdentifiable {
				var type: String {
					switch self {
					case .image(let value):
						return value.type
					case .audio(let value):
						return value.type
					}
				}
				var id: String {
					switch self {
					case .image(let value):
						return String(describing: value.id)
					case .audio(let value):
						return String(describing: value.id)
					}
				}
			}

			extension Attachment: Codable {
				init(from decoder: any Decoder) throws {
					let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
					let type = try container.decode(String.self, forKey: .type)
					switch type {
					case Image.FieldSet.resourceType:
					    self = try .image(Image(from: decoder))
					case Audio.FieldSet.resourceType:
					    self = try .audio(Audio(from: decoder))
					default:
						throw JSONAPIDecodingError.unhandledResourceType(Self.self, type)
					}
				}
				func encode(to encoder: any Encoder) throws {
					switch self {
					case .image(let value):
					    try value.encode(to: encoder)
					case .audio(let value):
					    try value.encode(to: encoder)
					}
				}
			}
			"""
		}
	}

	func testResourceUnionAccessControl() {
		assertMacro {
			"""
			@ResourceUnion
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}
			"""
		} expansion: {
			"""
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}

			extension Attachment: JSONAPI.ResourceIdentifiable {
				public var type: String {
					switch self {
					case .image(let value):
						return value.type
					case .audio(let value):
						return value.type
					}
				}
				public var id: String {
					switch self {
					case .image(let value):
						return String(describing: value.id)
					case .audio(let value):
						return String(describing: value.id)
					}
				}
			}

			extension Attachment: Codable {
				public init(from decoder: any Decoder) throws {
					let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
					let type = try container.decode(String.self, forKey: .type)
					switch type {
					case Image.FieldSet.resourceType:
					    self = try .image(Image(from: decoder))
					case Audio.FieldSet.resourceType:
					    self = try .audio(Audio(from: decoder))
					default:
						throw JSONAPIDecodingError.unhandledResourceType(Self.self, type)
					}
				}
				public func encode(to encoder: any Encoder) throws {
					switch self {
					case .image(let value):
					    try value.encode(to: encoder)
					case .audio(let value):
					    try value.encode(to: encoder)
					}
				}
			}
			"""
		}
	}

	func testResourceUnionAvailability() {
		assertMacro {
			"""
			@available(macOS, unavailable)
			@ResourceUnion
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}
			"""
		} expansion: {
			"""
			@available(macOS, unavailable)
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}

			@available(macOS, unavailable)
			extension Attachment: JSONAPI.ResourceIdentifiable {
				public var type: String {
					switch self {
					case .image(let value):
						return value.type
					case .audio(let value):
						return value.type
					}
				}
				public var id: String {
					switch self {
					case .image(let value):
						return String(describing: value.id)
					case .audio(let value):
						return String(describing: value.id)
					}
				}
			}

			@available(macOS, unavailable)
			extension Attachment: Codable {
				public init(from decoder: any Decoder) throws {
					let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
					let type = try container.decode(String.self, forKey: .type)
					switch type {
					case Image.FieldSet.resourceType:
					    self = try .image(Image(from: decoder))
					case Audio.FieldSet.resourceType:
					    self = try .audio(Audio(from: decoder))
					default:
						throw JSONAPIDecodingError.unhandledResourceType(Self.self, type)
					}
				}
				public func encode(to encoder: any Encoder) throws {
					switch self {
					case .image(let value):
					    try value.encode(to: encoder)
					case .audio(let value):
					    try value.encode(to: encoder)
					}
				}
			}
			"""
		}
	}
}
