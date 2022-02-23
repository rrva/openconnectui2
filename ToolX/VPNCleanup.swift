import Foundation
import SystemConfiguration

func removeDNSAndVPNInterface(
  vpnGateway: String, tunDev: String, internalIp4Address: String,
  withReply reply: @escaping (String) -> Void
) {
  if !hostMatcher.matches(vpnGateway) {
    reply("Invalid characters in vpnGateway")
    return
  }
  let out = ToolX.removeDNSAndVPNInterface(
    vpnGateway: vpnGateway, tunDev: tunDev, internalIp4Address: internalIp4Address)
  do {
    let pipe = Pipe()
    let task = try safeShell("route delete \(vpnGateway)", pipe: pipe)
    task.waitUntilExit()
  } catch {
    NSLog("\(error)")
  }
  reply(out)
}

func callback(store: SCDynamicStore, changedKeys: CFArray, context: UnsafeMutableRawPointer?) {
  guard context != nil else { return }
}

func removeDNSAndVPNInterface(vpnGateway: String, tunDev: String, internalIp4Address: String)
  -> String
{
  var out = "Removing any VPN DNS entries and IP addresses for tun \(tunDev)\n"
  guard let store = SCDynamicStoreCreate(nil, "OpenConnectUI2-ToolX" as NSString, nil, nil) else {
    out += "Could not connect SCDynamicStoreCreate\n"
    return out
  }

  let dnsKey = "State:/Network/Service/\(tunDev)/DNS" as NSString
  guard let searchDomainKeys = SCDynamicStoreCopyKeyList(store, dnsKey) as? [CFString] else {
    out += "Could not find any DNS entries\n"
    return out
  }

  if searchDomainKeys.isEmpty {
    out += "Nothing to do in \(dnsKey)\n"
    return out
  }

  for key in searchDomainKeys {
    let keyStr = (key as String)
    let ipv4Key = String(keyStr.prefix(keyStr.count - 3)) + "IPv4"

    if SCDynamicStoreRemoveValue(store, key) {
      out += "removed DNS entry for \(key)\n"
    } else {
      out += "Could not remove DNS entry for \(key)\n"

    }
    if SCDynamicStoreRemoveValue(store, ipv4Key as CFString) {
      out += "removed IPv4 network address for \(ipv4Key)\n"
      out += "\(key)\n"
    } else {
      out += "Could not remove IPv4 network entry for \(ipv4Key)\n"

    }

  }

  return out
}

func doRemoveDNSAndVPNInterface(
  _ vpnGateway: String, _ reply: (String) -> Void, _ tunDev: String, _ internalIp4Address: String
) {
  if !hostMatcher.matches(vpnGateway) {
    reply("Invalid characters in vpnGateway")
    return
  }
  let out = ToolX.removeDNSAndVPNInterface(
    vpnGateway: vpnGateway, tunDev: tunDev, internalIp4Address: internalIp4Address)
  do {
    let pipe = Pipe()
    let task = try safeShell("route delete \(vpnGateway)", pipe: pipe)
    task.waitUntilExit()
  } catch {
    NSLog("\(error)")
  }
  reply(out)
}
