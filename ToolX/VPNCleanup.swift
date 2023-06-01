import Foundation
import SystemConfiguration

func removeDNSAndVPNInterface(
  vpnGateway: String, tunDev: String, internalIp4Address: String,
  withReply reply: @escaping (String) -> Void
) {
  if vpnGateway != "" && !hostMatcher.matches(vpnGateway) {
    reply("Invalid characters in vpnGateway: [\(vpnGateway)]")
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

func getDefaultRouteInterface() -> String? {
  let dynamicStore = SCDynamicStoreCreate(nil, "NetworkSettings" as CFString, nil, nil)
  let key = "State:/Network/Global/IPv4" as CFString
  guard let value = SCDynamicStoreCopyValue(dynamicStore, key) as? [String: AnyObject],
    let primaryInterface = value["PrimaryInterface"] as? String
  else {
    print("Could not find the default route interface.")
    return nil
  }
  return primaryInterface
}

func userFriendlyInterfaceName(for interface: String) -> String? {
  let ifName = interface as CFString
  guard let networkInterfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else {
    print("Could not get network interfaces.")
    return nil
  }

  for networkInterface in networkInterfaces {
    if let bsdName = SCNetworkInterfaceGetBSDName(networkInterface),
      bsdName as String == interface
    {
      return SCNetworkInterfaceGetLocalizedDisplayName(networkInterface) as String?
    }
  }
  return nil
}

func doRestoreDNS() -> String? {
  if let defaultInterface = getDefaultRouteInterface() {
    if let userFriendlyName = userFriendlyInterfaceName(for: defaultInterface) {
      return resetDNS(interfaceName: userFriendlyName)
    } else {
      return "Unable to get user-friendly interface name for \(defaultInterface)"
    }
  } else {
    return "Unable to find default network interface to reset DNS for"
  }
}

func resetDNS(interfaceName: String) -> String? {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
  process.arguments = ["-setdnsservers", interfaceName, "Empty"]

  let outputPipe = Pipe()
  process.standardOutput = outputPipe

  do {
    try process.run()
    process.waitUntilExit()
    return "DNS servers reset for interface: \(interfaceName)"
  } catch {
    return "Error running networksetup command: \(error)"
  }
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
  if vpnGateway != "" && !hostMatcher.matches(vpnGateway) {
    reply("Invalid characters in vpnGateway [\(vpnGateway)]")
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
