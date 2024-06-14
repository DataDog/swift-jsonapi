// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// An error that occurs during the decoding of a JSON:API document.
public enum JSONAPIDecodingError: Error {
	/// Indicates that the decoder found an unhandled resource type when decoding a type annotated with the
	/// ``ResourceUnion()`` macro.
	///
	/// As associated values this case contains the union type and the unhandled resource type string.
	case unhandledResourceType(any Any.Type, String)
}
