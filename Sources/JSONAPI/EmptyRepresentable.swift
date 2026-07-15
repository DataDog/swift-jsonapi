// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation

/// A type that can represent an empty, or absent, value.
///
/// The JSON:API specification states that a resource object "MAY contain" `attributes` and
/// `relationships` — neither is guaranteed to be present. Conform a ``ResourceDefinition``'s
/// `Attributes` or `Relationships` type to `EmptyRepresentable` to let ``Resource`` decode
/// successfully even when the corresponding top-level member is entirely absent from the
/// payload, falling back to ``empty`` instead of throwing a decoding error.
///
/// This mirrors the special handling ``Resource`` already gives to ``Unit`` for resource
/// definitions that have no attributes or relationships at all, but for types that normally
/// carry a value and simply tolerate its absence.
public protocol EmptyRepresentable {
	static var empty: Self { get }
}
