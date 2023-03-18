import Foundation

@objc
public protocol ToolXProtocol {
  func startOpenConnect(
    localUser: String,
    username: String,
    password: String,
    vpnHost: String,
    programPath: String,
    withReply reply: @escaping (FileHandle) -> Void
  )
  func runVpnC(
    env: [String: String],
    withReply reply: @escaping (FileHandle) -> Void
  )
  func stopOpenConnect(withReply reply: @escaping (String) -> Void)
  func removeDNSAndVPNInterface(
    vpnGateway: String, tunDev: String,
    internalIp4Address: String, withReply reply: @escaping (String) -> Void)
  func restoreDNS(withReply reply: @escaping (String) -> Void)
  func version(withReply reply: @escaping (String) -> Void)
  func die()
  func openConnectPid(withReply reply: @escaping (pid_t) -> Void)
  @available(macOS 10.15.4, *)
  func upgrade(
    download: FileHandle,
    downloadSize: Int,
    appLocation: URL,
    pid: Int32,
    user: UInt32,
    withReply reply: @escaping (FileHandle) -> Void)
}
