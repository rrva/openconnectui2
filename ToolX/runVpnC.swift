import Foundation

func runVpnc() {
  let openConnect = locateOpenConnect()
  let vpnC = locateOpenConnectVpnC(openConnect).unsafelyUnwrapped
  let task = Process()
  let pipe = Pipe()
  task.standardOutput = pipe
  task.standardError = pipe
  task.environment = ProcessInfo.processInfo.environment
  task.executableURL = URL(fileURLWithPath: vpnC)
  print("Running \(vpnC)")
  pipe.fileHandleForReading.readabilityHandler = { pipe in
    if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
      if !pipe.availableData.isEmpty {
        print(line)
      }
    } else {
      print("Error decoding data: \(pipe.availableData)")
    }
  }
  do {
    try task.run()
  } catch {
    print("\(error)")
  }

  task.waitUntilExit()
}

func printVpncParams() {
  guard let vpnGateway = ProcessInfo.processInfo.environment["VPNGATEWAY"] else {
    return
  }
  print("VPNGATEWAY=\(vpnGateway)")
  guard let tunDev = ProcessInfo.processInfo.environment["TUNDEV"] else {
    return
  }
  print("TUNDEV=\(tunDev)")
  guard let internalIp4Adress = ProcessInfo.processInfo.environment["INTERNAL_IP4_ADDRESS"] else {
    return
  }
  print("INTERNAL_IP4_ADDRESS=\(internalIp4Adress)")

}
