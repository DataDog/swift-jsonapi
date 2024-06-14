// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A type that can be identified as a JSON:API resource.
public protocol ResourceIdentifiable {
	associatedtype ID: Hashable & CustomStringConvertible

	var type: String { get }
	var id: ID { get }
}

extension ResourceIdentifiable where Self: ResourceDefinitionProviding {
	public var type: String {
		Definition.resourceType
	}
}
