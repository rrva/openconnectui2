import Foundation
import ServiceManagement

func installHelper(authorized: DispatchSemaphore, installed: DispatchSemaphore) {

  var authRef: AuthorizationRef?
  var authStatus = AuthorizationCreate(nil, nil, [.preAuthorize], &authRef)

  guard authStatus == errAuthorizationSuccess else {
    print("Unable to get a valid empty authorization reference to load Helper daemon")
    return
  }

  let authItem = "se.rrva.openconnectui2.ToolX".withCString { authorizationString in
    AuthorizationItem(name: authorizationString, valueLength: 0, value: nil, flags: 0)
  }

  let pointer = UnsafeMutablePointer<AuthorizationItem>.allocate(capacity: 1)
  pointer.initialize(to: authItem)

  defer {
    pointer.deinitialize(count: 1)
    pointer.deallocate()
  }

  var authRights = AuthorizationRights(count: 1, items: pointer)

  let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
  authStatus = AuthorizationCreate(&authRights, nil, flags, &authRef)

  authorized.signal()

  guard authStatus == errAuthorizationSuccess else {
    print("Unable to get a valid loading authorization reference to load Helper daemon")
    return
  }

  var error: Unmanaged<CFError>?
  let installResult = SMJobBless(
    kSMDomainSystemLaunchd, "se.rrva.OpenConnectUI2.ToolX" as CFString, authRef, &error)
  if installResult == false {
    let blessError = error!.takeRetainedValue() as Error
    NSLog("Error while installing the Helper: \(blessError.localizedDescription)")
    installed.signal()
    return
  }

  UserDefaults.standard.set("YES", forKey: "helperInstalled")

  AuthorizationFree(authRef!, [])

  installed.signal()
}
