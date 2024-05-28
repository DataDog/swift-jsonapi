import Foundation
import JSONAPI
import SnapshotTesting

extension Snapshotting where Format == String {
	static func jsonAPI() -> Snapshotting where Value: ResourceObjectIdentifiable & Encodable {
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
		Value.Element: ResourceObjectIdentifiable & Encodable
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
