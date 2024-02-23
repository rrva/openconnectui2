import AppKit
import Foundation

class ToolXService: NSObject, ToolXProtocol {
  func restoreDNS(networkInterface: String, withReply reply: @escaping (String) -> Void) {
    reply(doRestoreDNS(networkInterface: networkInterface) ?? "")
  }

  func runVpnC(env: [String: String], withReply reply: @escaping (FileHandle) -> Void) {
    let openConnect = locateOpenConnect()
    let vpnC = locateOpenConnectVpnC(openConnect).unsafelyUnwrapped
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    let allowedKeys: Set = [
      "reason",
      "VPNGATEWAY",
      "VPNPID",
      "TUNDEV",
      "IDLE_TIMEOUT",
      "LOG_LEVEL",
      "INTERNAL_IP4_ADDRESS",
      "INTERNAL_IP4_MTU",
      "INTERNAL_IP4_NETMASK",
      "INTERNAL_IP4_NETMASKLEN",
      "INTERNAL_IP4_NETADDR",
      "INTERNAL_IP4_DNS",
      "INTERNAL_IP4_NBNS",
      "INTERNAL_IP6_ADDRESS",
      "INTERNAL_IP6_NETMASK",
      "INTERNAL_IP6_DNS",
      "CISCO_DEF_DOMAIN",
      "CISCO_BANNER",
      "CISCO_SPLIT_DNS",
    ]
    var filteredEnv = [String: String]()
    env.keys.forEach { key in
      if allowedKeys.contains(key) {
        filteredEnv[key] = env[key]
      }
      if key.hasPrefix("CISCO_SPLIT_INC") {
        filteredEnv[key] = env[key]
      }
      if key.hasPrefix("CISCO_IPV6_SPLIT_INC") {
        filteredEnv[key] = env[key]
      }
    }
    task.environment = filteredEnv
    task.executableURL = URL(fileURLWithPath: vpnC)
    let reason = filteredEnv["reason"]
    NSLog("Running \(vpnC) reason: \(String(describing: reason))")
    filteredEnv.forEach { key, value in
      if !key.hasPrefix("CISCO_SPLIT_INC") {
        pipe.fileHandleForWriting.write("\(key)=\(value)\n".data(using: .utf8)!)
      }
    }
    do {
      try task.run()
    } catch {
      pipe.fileHandleForWriting.write("\(error)".data(using: .utf8)!)
      reply(pipe.fileHandleForReading)
    }
    reply(pipe.fileHandleForReading)
    task.waitUntilExit()
  }

  @available(macOS 10.15.4, *)
  func upgrade(
    download: FileHandle, downloadSize: Int, appLocation: URL, pid: Int32, user: UInt32,
    withReply reply: @escaping (FileHandle) -> Void
  ) {
    performUpgrade(
      download: download, downloadSize: downloadSize, appLocation: appLocation, pid: pid,
      user: user, withReply: reply)
  }

  func die() {
    exit(EXIT_SUCCESS)
  }

  func version(withReply reply: @escaping (String) -> Void) {
    if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
      reply(version)
    } else {
      reply("error")
    }
  }

  func defaultNetworkInterface(withReply reply: @escaping (String) -> Void) {
    if let defaultInterface = getDefaultRouteInterface() {
      if let userFriendlyName = userFriendlyInterfaceName(for: defaultInterface) {
        reply(userFriendlyName)
      } else {
        reply("error: Unable to get user-friendly interface name for \(defaultInterface)")
      }
    } else {
      reply("error: Unable to find default network interface to reset DNS for")
    }
  }

  func startOpenConnect(
    localUser: String,
    username: String,
    password: String,
    vpnHost: String,
    programPath: String,
    customArgs: String?,
    withReply reply: @escaping (FileHandle) -> Void
  ) {
    doStartOpenConnect(
      localUser: localUser, username: username, password: password, vpnHost: vpnHost,
      programPath: programPath,
      customArgs: customArgs,
      withReply: reply)
  }

  func stopOpenConnect(withReply reply: @escaping (String) -> Void) {
    doStopOpenConnect(reply)
  }

  let hostMatcher = try! NSRegularExpression(pattern: "^[A-Za-z0-9._\\-/:+%?&=]+$")

  func removeDNSAndVPNInterface(
    vpnGateway: String, tunDev: String, internalIp4Address: String,
    withReply reply: @escaping (String) -> Void
  ) {
    doRemoveDNSAndVPNInterface(vpnGateway, reply, tunDev, internalIp4Address)
  }
}
