import Foundation
import ServiceManagement

func addOrUpdatePassword(_ service: String, account: String, password: String) -> Bool {
  let passwordData = password.data(using: .utf8)!
  let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
  ]

  let attributesToUpdate: [String: Any] = [
    kSecValueData as String: passwordData
  ]

  var status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

  if status == errSecItemNotFound {
    var newQuery = query
    newQuery[kSecValueData as String] = passwordData
    status = SecItemAdd(newQuery as CFDictionary, nil)
  }

  return status == errSecSuccess
}

func getPassword(_ service: String, account: String) -> String? {
  let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
    kSecMatchLimit as String: kSecMatchLimitOne,
    kSecReturnData as String: true,
  ]

  var item: AnyObject?
  let status = SecItemCopyMatching(query as CFDictionary, &item)

  guard status == errSecSuccess, let passwordData = item as? Data,
    let password = String(data: passwordData, encoding: .utf8)
  else {
    return nil
  }

  return password
}
