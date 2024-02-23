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
    let task = try safeShellWithArgs(
      executable: "/sbin/route", args: ["delete", vpnGateway], pipe: pipe)
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

func getPrimaryNetworkService() -> String? {
  let dynamicStore = SCDynamicStoreCreate(nil, "NetworkSettings" as CFString, nil, nil)
  let key = "State:/Network/Global/IPv4" as CFString
  guard let value = SCDynamicStoreCopyValue(dynamicStore, key) as? [String: AnyObject],
    let primaryInterface = value["PrimaryService"] as? String
  else {
    print("Could not find the primary network service.")
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

func doRestoreDNS(networkInterface: String) -> String? {
  return resetDNS(interfaceName: networkInterface)
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
  guard let store = SCDynamicStoreCreate(nil, "OpenConnectUI2-ToolX" as CFString, nil, nil) else {
    out += "Could not connect to SCDynamicStoreCreate\n"
    return out
  }

  guard let primaryNetworkService = getPrimaryNetworkService() else {
    out += "Could not find primary network service name\n"
    return out
  }

  let primaryDnsKey = "State:/Network/Service/\(primaryNetworkService)/DNS" as CFString
  let tunDevDnsKey = "State:/Network/Service/\(tunDev)/DNS" as CFString

  guard
    let currentTunDNSConfig = SCDynamicStoreCopyValue(store, tunDevDnsKey) as? [String: AnyObject]
  else {
    out += "Could not find tun dns config at \(tunDevDnsKey)\n"
    return out
  }

  SCDynamicStoreRemoveValue(store, tunDevDnsKey)

  guard
    var currentPrimaryDNSConfig = SCDynamicStoreCopyValue(store, primaryDnsKey)
      as? [String: AnyObject]
  else {
    out += "Could not find primary dns config at \(primaryDnsKey)\n"
    return out
  }


  out += "Current Primary DNS Configuration: \(currentPrimaryDNSConfig)\n"
  out += "Current DNS Configuration for \(tunDev): \(currentTunDNSConfig)\n"

  let vpnDnsServers = currentTunDNSConfig["ServerAddresses"] as? [String] ?? []
  let primaryDnsServers = currentPrimaryDNSConfig["ServerAddresses"] as? [String] ?? []

  let filteredPrimaryDnsServers = primaryDnsServers.filter { !vpnDnsServers.contains($0) }

  if !filteredPrimaryDnsServers.isEmpty {
    currentPrimaryDNSConfig["ServerAddresses"] = filteredPrimaryDnsServers as AnyObject?

    if SCDynamicStoreSetValue(store, primaryDnsKey, currentPrimaryDNSConfig as CFDictionary) {
      out += "Successfully updated DNS Configuration\n"
    } else {
      out += "Failed to update DNS Configuration\n"
    }

    if let updatedDNSConfig = SCDynamicStoreCopyValue(store, primaryDnsKey) {
      out += "Updated DNS Configuration: \(updatedDNSConfig)\n"
    } else {
      out += "No updated DNS configuration found\n"
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
    let task = try safeShellWithArgs(
      executable: "/sbin/route", args: ["delete", vpnGateway], pipe: pipe)
    task.waitUntilExit()
  } catch {
    NSLog("\(error)")
  }

  reply(out)
}
