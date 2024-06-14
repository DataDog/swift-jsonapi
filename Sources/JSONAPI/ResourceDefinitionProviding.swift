// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A type that provides a JSON:API resource definition.
public protocol ResourceDefinitionProviding {
	associatedtype Definition: ResourceDefinition
}
