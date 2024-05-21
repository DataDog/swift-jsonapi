import Foundation

public enum ResourceCodingKeys: String, CodingKey {
	case type, id, attributes, relationships
}

extension KeyedDecodingContainer where Key == ResourceCodingKeys {
	public func checkResourceType<T>(_: T.Type, _ expectedType: String) throws {
		let type = try self.decode(String.self, forKey: .type)
		if type != expectedType {
			throw DecodingError.typeMismatch(
				T.self,
				.init(
					codingPath: [ResourceCodingKeys.type],
					debugDescription: "Resource type '\(type)' does not match expected type '\(expectedType)'"
				)
			)
		}
	}
}
