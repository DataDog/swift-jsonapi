import Foundation

public enum ResourceCodingKeys: String, CodingKey {
	case type, id, attributes, relationships
}

extension KeyedDecodingContainer where Key == ResourceCodingKeys {
	public func checkResourceType<T>(_: T.Type) throws where T: ResourceType {
		let type = try self.decode(String.self, forKey: .type)
		if type != T.resourceType {
			throw DecodingError.typeMismatch(
				T.self,
				.init(
					codingPath: [ResourceCodingKeys.type],
					debugDescription: "Resource type '\(type)' does not match expected type '\(T.resourceType)'"
				)
			)
		}
	}
}
