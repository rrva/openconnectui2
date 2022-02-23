import Foundation
import Network

func main() {
  let arguments = CommandLine.arguments
  fixPermsIfNeeded(path: Bundle.main.executablePath.unsafelyUnwrapped)
  if arguments.contains("vpnc") {
    guard let reason = ProcessInfo.processInfo.environment["reason"] else {
      return
    }
    if reason != "connect" {
      exit(EXIT_SUCCESS)
    }
    print("Started as vpnc helper")
    printVpncParams()
    runVpnc()
    print("vpnc helper done")
    exit(EXIT_SUCCESS)
  } else {

    NSLog("started as XPC helper")
    let delegate = ToolXDelegate()
    let listener = NSXPCListener(machServiceName: "se.rrva.OpenConnectUI2.ToolX")
    listener.delegate = delegate
    listener.resume()
    RunLoop.main.run()
    NSLog("exiting")
    exit(EXIT_SUCCESS)
  }

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
