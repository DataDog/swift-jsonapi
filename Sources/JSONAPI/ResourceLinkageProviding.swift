// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A type that provides resource linkage for an identifier type.
public protocol ResourceLinkageProviding {
	associatedtype ID

	static func resourceIdentifier(_ id: ID) -> ResourceIdentifier
}

extension ResourceLinkageProviding where Self: ResourceDefinitionProviding, ID: CustomStringConvertible {
	public static func resourceIdentifier(_ id: ID) -> ResourceIdentifier {
		ResourceIdentifier(type: Definition.resourceType, id: String(describing: id))
	}
}
