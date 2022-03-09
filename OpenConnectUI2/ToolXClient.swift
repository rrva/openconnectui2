import Foundation

func service() -> ToolXProtocol? {
  let connection = NSXPCConnection(machServiceName: "se.rrva.OpenConnectUI2.ToolX")
  connection.remoteObjectInterface = NSXPCInterface(with: ToolXProtocol.self)
  connection.resume()

  let service =
    connection.remoteObjectProxyWithErrorHandler { error in
      logger.log("createToolXRemoteService got error: \(error)")
    } as? ToolXProtocol
  return service
}

func performUpgrade(download: FileHandle, downloadSize: Int, logs: Logs, upgrade: Upgrade) {

  if #available(macOS 10.15.4, *) {
    service()?.upgrade(
      download: download, downloadSize: downloadSize, appLocation: Bundle.main.bundleURL,
      pid: ProcessInfo.processInfo.processIdentifier,
      user: getuid()
    ) { response in
      guard let reader = LineReader(fileHandle: response) else {
        return
      }
      var upgradeComplete = false
      reader.forEach { line in
        if line.trimmingCharacters(in: .whitespacesAndNewlines) == "Upgrade: Upgrade complete" {
          upgradeComplete = true
          DispatchQueue.main.async {
            upgrade.message = "Upgrade complete, please quit to restart"
          }
        }
        logs.log(line)

      }
      if !upgradeComplete {
        DispatchQueue.main.async {
          upgrade.message = "Upgrade failed, please check logs"
        }
      }

    }
  } else {
    // Fallback on earlier versions
  }
}

func killHelper() {
  service()?.die()
}

func isHelperInstalled(reply: @escaping (Bool) -> Void) {
  let versionChecked = DispatchSemaphore(value: 0)
  if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
    service()?.version { response in
      logger.log("Helper version installed: \(response) app version: \(version)")
      if version == response {
        versionChecked.signal()
        reply(true)
      } else {
        versionChecked.signal()
        reply(false)
      }
    }
  }
  let result = versionChecked.wait(timeout: .now() + 1.0)
  if result == DispatchTimeoutResult.timedOut {
    logger.log("Helper version unknown")
    reply(false)
  }
}

func checkHelperInstallation(install: @escaping (Bool) -> Void) {
  isHelperInstalled { installed in
    install(installed)
  }
}

func removeDNSAndVPNInterface() {
  let vpnGateway = UserDefaults.standard.object(forKey: "lastVpnGateway") as? String ?? ""
  let tunDev = UserDefaults.standard.object(forKey: "lastTunDev") as? String ?? ""
  let internalIp4Address =
    UserDefaults.standard.object(forKey: "lastInternalIp4Address") as? String ?? ""
  service()?.removeDNSAndVPNInterface(
    vpnGateway: vpnGateway, tunDev: tunDev, internalIp4Address: internalIp4Address
  ) { response in
    logger.log(response)
  }
}

func stopOpenConnect() {
  service()?.stopOpenConnect { _ in
    logger.log("openconnect stopped")
  }
}

func startOpenConnect(
  localUser: String, username: String, password: String,
  host: String,
  withReply reply: @escaping (Bool) -> Void
) {
  service()?.startOpenConnect(
    localUser: localUser, username: username, password: password, vpnHost: host
  ) { response in
    guard let reader = LineReader(fileHandle: response) else {
      return
    }
    reader.forEach { line in
      logger.log(
        maskPassword(line.trimmingCharacters(in: .whitespacesAndNewlines), password: password))
      if line.starts(with: "openconnect not found") {
        reply(false)
      }
      if line.starts(with: "Established") {
        reply(true)
      }
      if line.starts(with: "Reconnect failed") {
        reply(false)
      }
      if line.contains("fgets (stdin): Resource temporarily unavailable") {
        logger.log("Perhaps you entered the wrong password or your password expired?")
        reply(false)
      }
      if line.starts(with: "VPNGATEWAY=") {
        UserDefaults.standard.set(
          line.split(separator: "=")[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
          forKey: "lastVpnGateway")
      }
      if line.starts(with: "TUNDEV=") {
        UserDefaults.standard.set(
          line.split(separator: "=")[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
          forKey: "lastTunDev")
      }
    }
  }

}

func maskPassword(_ line: String, password: String) -> String {
  if !password.isEmpty && line.contains(password) {
    let result = line.replacingOccurrences(of: password, with: "************")
    return result
  } else {
    return line
  }
}
