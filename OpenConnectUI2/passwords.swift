import Foundation
import ServiceManagement

func addOrUpdatePassword(_ service: String, account: String, password: String) -> Bool {

  var item: SecKeychainItem?

  var status = SecKeychainFindGenericPassword(
    nil,
    UInt32(service.utf8.count),
    service,
    UInt32(account.utf8.count),
    account,
    nil,
    nil,
    &item
  )

  if item != nil {
    status = SecKeychainItemModifyContent(item!, nil, UInt32(password.utf8.count), password)
    return status == noErr
  } else {
    status = SecKeychainAddGenericPassword(
      nil,
      UInt32(service.utf8.count),
      service,
      UInt32(account.utf8.count),
      account,
      UInt32(password.utf8.count),
      password,
      nil)
    return status == errSecSuccess
  }
}

func getPassword(_ service: String, account: String) -> String? {
  var passwordLength: UInt32 = 0
  var password: UnsafeMutableRawPointer?

  let status = SecKeychainFindGenericPassword(
    nil,
    UInt32(service.utf8.count),
    service,
    UInt32(account.utf8.count),
    account,
    &passwordLength,
    &password,
    nil
  )

  if status == errSecSuccess {
    guard password != nil else { return nil }
    let result =
      NSString(
        bytes: password!, length: Int(passwordLength),
        encoding: String.Encoding.utf8.rawValue) as String?
    SecKeychainItemFreeContent(nil, password)
    return result
  }

  return nil
}
