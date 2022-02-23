import AppKit
import Foundation

class ToolXService: NSObject, ToolXProtocol {

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

  func startOpenConnect(
    localUser: String,
    username: String,
    password: String,
    vpnHost: String,
    withReply reply: @escaping (FileHandle) -> Void
  ) {
    doStartOpenConnect(
      localUser: localUser, username: username, password: password, vpnHost: vpnHost,
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
