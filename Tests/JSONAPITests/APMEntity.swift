import Foundation
import JSONAPI

@ResourceWrapper(type: "apm-entity")
public struct APMEntity: Identifiable {
    public var id: String

    @ResourceAttribute(key: "id_tags")
    public let idTags: IDTags

    @ResourceAttribute
    public let metadata: Metadata

    @ResourceAttribute
    public let stats: Stats

    @ResourceRelationship(key: "catalog_definition")
    public var catalogDefinition: CatalogDefinition?

    @ResourceRelationship(key: "type")
    public var entityType: EntityType

    @ResourceRelationship(key: "monitor_counts")
    public var monitorCounts: MonitorCounts?

    public struct IDTags: Codable {
        let service: String
    }

    public struct Metadata: Codable {
        let isTraced: Bool
        let isUSM: Bool
        let isFavorite: Bool?
        let color: String?

        enum CodingKeys: String, CodingKey {
            case isTraced = "is_traced"
            case isUSM = "is_usm"
            case isFavorite = "is_favorite"
            case color
        }
    }

    public struct Stats: Codable {
        let operation: String
        let hits: String?
        let errors: String?
        let errorsPercentage: Double?
        let totalDuration: String?
        let latencyAverage: Double?
        let latencyP50: Double?
        let latencyP75: Double?
        let latencyP90: Double?
        let latencyP95: Double?
        let latencyP99: Double?
        let latencyMax: Double?

        enum CodingKeys: String, CodingKey {
            case operation, hits, errors
            case errorsPercentage = "errors_percentage"
            case totalDuration = "total_duration"
            case latencyAverage = "latency_avg"
            case latencyP50 = "latency_p50"
            case latencyP75 = "latency_p75"
            case latencyP90 = "latency_p90"
            case latencyP95 = "latency_p95"
            case latencyP99 = "latency_p99"
            case latencyMax = "latency_max"
        }
    }

    @ResourceWrapper(type: "apm-catalog-definition")
    public struct CatalogDefinition {
        public var id: String

        @ResourceAttribute
        public let team: String?
    }

    @ResourceWrapper(type: "apm-entity-type")
    public struct EntityType {
        public var id: String

        @ResourceAttribute
        public let catalog: Catalog

        public struct Catalog: Codable {
            public let kind: String
            public let service: Service?

            public struct Service: Codable {
                public let type: String
            }
        }
    }

    @ResourceWrapper(type: "apm-monitor-counts")
    public struct MonitorCounts {
        public var id: String

        @ResourceAttribute(key: "non_synthetics_monitors")
        public var nonSyntheticsMonitors: Metadata?

        @ResourceAttribute(key: "synthetics_monitors")
        public var syntheticsMonitors: Metadata?

        public struct Metadata: Codable {
            let alert: Int
            let warn: Int
            let ok: Int
            let noData: Int

            enum CodingKeys: String, CodingKey {
                case alert
                case warn
                case ok
                case noData = "no_data"
            }
        }
    }
}
