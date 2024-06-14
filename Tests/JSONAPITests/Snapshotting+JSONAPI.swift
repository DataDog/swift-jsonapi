// Unless explicitly stated otherwise all files in this repository are licensed under
// the MIT License.
//
// This product includes software developed at Datadog (https://www.datadoghq.com/).
// Copyright 2024-Present Datadog, Inc.

import Foundation
import JSONAPI
import SnapshotTesting

extension Snapshotting where Format == String {
	static func jsonAPI() -> Snapshotting where Value: ResourceIdentifiable & Encodable {
		let encoder = JSONAPIEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

		var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
			try! String(decoding: encoder.encode(encodable), as: UTF8.self)
		}
		snapshotting.pathExtension = "json"
		return snapshotting
	}

	static func jsonAPI() -> Snapshotting
	where
		Value: Collection & Encodable,
		Value.Element: ResourceIdentifiable & Encodable
	{
		let encoder = JSONAPIEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

		var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
			try! String(decoding: encoder.encode(encodable), as: UTF8.self)
		}
		snapshotting.pathExtension = "json"
		return snapshotting
	}

	static func jsonAPI<PrimaryData, Meta>() -> Snapshotting
	where
		PrimaryData: Encodable, Meta: Encodable,
		Value == CompoundDocument<PrimaryData, Meta>
	{
		let encoder = JSONAPIEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

		var snapshotting = SimplySnapshotting.lines.pullback { (encodable: Value) in
			try! String(decoding: encoder.encode(encodable), as: UTF8.self)
		}
		snapshotting.pathExtension = "json"
		return snapshotting
	}
}
