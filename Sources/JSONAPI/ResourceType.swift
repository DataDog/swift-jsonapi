import Foundation

public struct ResourceType<T> where T: Resource {
}

extension ResourceType: Decodable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let type = try container.decode(String.self)

    guard type == T.type else {
      throw DecodingError.typeMismatch(
        T.self,
        .init(
          codingPath: [ResourceCodingKeys.type],
          debugDescription: "Resource type does not match: '\(type)'"
        )
      )
    }
  }
}
