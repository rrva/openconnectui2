import Foundation

func locateOpenConnect() -> String? {
  if let file = canonicalPath("/opt/homebrew/bin/openconnect") {
    return file
  } else if let file = canonicalPath("/usr/local/bin/openconnect") {
    return file
  }
  return locateOpenConnectViaPath()
}

func locateOpenConnectViaPath() -> String? {
  if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
    let paths = pathEnv.split(separator: ":")
    for path in paths {
      if let file = canonicalPath("\(path)/openconnect") {
        return file
      }
    }
    return nil
  }
  return nil
}

func locateOpenConnectVpnC(_ openConnectPath: String?) -> String? {
  if openConnectPath == nil {
    return nil
  }
  let url = NSURL(fileURLWithPath: openConnectPath!)
  if let dirUrl = url.deletingLastPathComponent?.path {
    let vpncScript = NSURL(fileURLWithPath: "\(dirUrl)/../etc/vpnc-script")
    if let path = vpncScript.standardized?.path {
      let vpncScriptPath = canonicalPath(path)
      if vpncScriptPath == nil {
        let vpncScriptNewLocation = NSURL(fileURLWithPath: "\(dirUrl)/../etc/vpnc/vpnc-script")
        if let path = vpncScriptNewLocation.standardized?.path {
          return canonicalPath(path)
        }
      } else {
        return vpncScriptPath
      }
    }
  }
  return nil
}

func canonicalPath(_ fileName: String) -> String? {
  print("Looking for \(fileName)...", terminator: "")
  let url = NSURL(fileURLWithPath: fileName)
  var error: NSError?
  let exists = url.checkResourceIsReachableAndReturnError(&error)
  if exists {
    print(" found")
    return url.standardized?.path
  } else {
    print(" not found")
    return nil
  }
}
