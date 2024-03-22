import Foundation

public enum DocumentDecodingError: Error {
  case includedResourceDecodingNotEnabled
}

public enum DocumentEncodingError: Error {
  case includedResourceEncodingNotEnabled
}
