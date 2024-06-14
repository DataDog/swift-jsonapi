// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A unique identifier for a JSON:API resource.
public struct ResourceIdentifier: Hashable, Codable {
	public var type: String
	public var id: String

	public init(type: String, id: String) {
		self.type = type
		self.id = id
	}

	public init<R>(_ resource: R) where R: ResourceIdentifiable {
		self.init(type: resource.type, id: resource.id.description)
	}
}
