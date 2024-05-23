import JSONAPIMacros
import MacroTesting
import SwiftSyntaxMacros
import XCTest

final class CodableResourceUnionMacroTests: XCTestCase {
	override func invokeTest() {
		withMacroTesting(
			// isRecording: true,
			macros: [CodableResourceUnionMacro.self]
		) {
			super.invokeTest()
		}
	}

	func testCodableResourceConformance() {
		assertMacro {
			"""
			@CodableResourceUnion
			enum Attachment: Equatable {
				case image(Image)
				case audio(Audio)
			}
			"""
		} expansion: {
			#"""
			enum Attachment: Equatable {
				case image(Image)
				case audio(Audio)
			}

			extension Attachment: JSONAPI.CodableResource {
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
				init(from decoder: any Decoder) throws {
					let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
					let type = try container.decode(String.self, forKey: .type)
					switch type {
					case Image.resourceType:
					    self = try .image(Image(from: decoder))
					case Audio.resourceType:
					    self = try .audio(Audio(from: decoder))
					default:
						throw DecodingError.typeMismatch(
							Self.self,
							.init(
								codingPath: [ResourceCodingKeys.type],
								debugDescription: "Resource type '\(type)' not found in union."
							)
						)
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
			"""#
		}
	}

	func testAccessControl() {
		assertMacro {
			"""
			@CodableResourceUnion
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}
			"""
		} expansion: {
			#"""
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}

			extension Attachment: JSONAPI.CodableResource {
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
				public init(from decoder: any Decoder) throws {
					let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
					let type = try container.decode(String.self, forKey: .type)
					switch type {
					case Image.resourceType:
					    self = try .image(Image(from: decoder))
					case Audio.resourceType:
					    self = try .audio(Audio(from: decoder))
					default:
						throw DecodingError.typeMismatch(
							Self.self,
							.init(
								codingPath: [ResourceCodingKeys.type],
								debugDescription: "Resource type '\(type)' not found in union."
							)
						)
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
			"""#
		}
	}

	func testAvailability() {
		assertMacro {
			"""
			@available(macOS, unavailable)
			@CodableResourceUnion
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}
			"""
		} expansion: {
			#"""
			@available(macOS, unavailable)
			public enum Attachment: Equatable {
				case image(Image), audio(Audio)
			}

			@available(macOS, unavailable)
			extension Attachment: JSONAPI.CodableResource {
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
				public init(from decoder: any Decoder) throws {
					let container = try decoder.container(keyedBy: ResourceCodingKeys.self)
					let type = try container.decode(String.self, forKey: .type)
					switch type {
					case Image.resourceType:
					    self = try .image(Image(from: decoder))
					case Audio.resourceType:
					    self = try .audio(Audio(from: decoder))
					default:
						throw DecodingError.typeMismatch(
							Self.self,
							.init(
								codingPath: [ResourceCodingKeys.type],
								debugDescription: "Resource type '\(type)' not found in union."
							)
						)
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
			"""#
		}
	}
}
