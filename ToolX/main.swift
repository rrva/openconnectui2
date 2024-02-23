import Foundation
import Network

let applicationSupportDirectory = "/Library/Application Support/OpenConnectUI2"
let tunDevFilename = "tundev.txt"

func readTunDevValue() -> String? {
  let filePath = "\(applicationSupportDirectory)/\(tunDevFilename)"

  let fileURL = URL(fileURLWithPath: filePath)

  do {
    let tunDevValue = try String(contentsOf: fileURL, encoding: .utf8)
    return tunDevValue
  } catch {
    NSLog("Failed to read TUNDEV value: \(error)")
    return nil
  }
}

func main() {
  let signalSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
  signalSource.setEventHandler {
    NSLog("Shutdown cleanup, remove DNS and VPN interface")
    if let tunDev = readTunDevValue() {
      let result = removeDNSEntriesForVPN(tunDev: tunDev)
      NSLog("removeDNSEntriesForVPN: \(result)")
      if let networkInterface = getDefaultRouteInterface() {
        if let friendlyInterfaceName = userFriendlyInterfaceName(for: networkInterface) {
          let restoreResult = doRestoreDNS(networkInterface: friendlyInterfaceName)
          NSLog("doRestoreDNS: \(String(describing: restoreResult))")
        }
      }
    }
    NSLog("Shutdown cleanup, done")
  }
  signalSource.resume()
  signal(SIGTERM, SIG_IGN)

  fixPermsIfNeeded(path: Bundle.main.executablePath.unsafelyUnwrapped)
  NSLog("started as XPC helper")
  let delegate = ToolXDelegate()
  let listener = NSXPCListener(machServiceName: "se.rrva.OpenConnectUI2.ToolX")
  listener.delegate = delegate
  listener.resume()
  RunLoop.main.run()
  NSLog("exiting")
  exit(EXIT_SUCCESS)
}
main()

func fixPermsIfNeeded(path: String) {

  let fm = FileManager.default
  var attributes = [FileAttributeKey: Any]()

  do {
    attributes = try fm.attributesOfItem(atPath: path)
  } catch let error {
    print("Permissions error: \(error)")
  }

  if attributes[.posixPermissions] as! Int != 0o755 {
    attributes[.posixPermissions] = 0o755

    do {
      try fm.setAttributes(attributes, ofItemAtPath: path)
    } catch let error {
      print("Permissions error: \(error)")
    }
  }
}
