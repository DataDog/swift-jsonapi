// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A property wrapper that decodes a `nil` value into an empty instance.
///
/// Use the `DefaultEmpty` property wrapper on `RangeReplaceableCollection` properties to decode `nil` values into
/// empty collections instead of using an optional type.
@propertyWrapper
public struct DefaultEmpty<T> where T: RangeReplaceableCollection {
	public var wrappedValue: T

	public init(wrappedValue: T) {
		self.wrappedValue = wrappedValue
	}
}

extension DefaultEmpty: Decodable where T: Decodable, T.Element: Decodable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		if container.decodeNil() {
			self.wrappedValue = T()
		} else {
			self.wrappedValue = try container.decode(T.self)
		}
	}
}

extension DefaultEmpty: Encodable where T: Encodable {
	public func encode(to encoder: any Encoder) throws {
		try wrappedValue.encode(to: encoder)
	}
}

extension DefaultEmpty: Equatable where T: Equatable {
}

extension DefaultEmpty: Hashable where T: Hashable {
}
