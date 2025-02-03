// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// An error that occurs during the encoding of a JSON:API document.
public enum JSONAPIEncodingError: Error {
	/// Indicates that the encoder couldn't find the associated resource encoder.
	///
	/// This error typically happens when trying to encode a JSON:API resource using a `JSONEncoder`
	/// instead of a ``JSONAPIEncoder``.
	case resourceEncoderNotFound
}
