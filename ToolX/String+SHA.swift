import CommonCrypto
import Foundation

extension String {
  public func sha256() -> String? {
    guard let data: Data = data(using: .utf8) else {
      return nil
    }
    var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    data.withUnsafeBytes {
      _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
    }

    return Data(buffer).base64EncodedString()
  }
}
