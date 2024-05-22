import Foundation

public enum JSONAPIDecodingError: Error {
	case unhandledResourceType(any Any.Type, String)
}
