import Cocoa
import Foundation
import Network
import SwiftUI

func main() {

  let app = NSApplication.shared

  let authorized = DispatchSemaphore(value: 0)
  let installed = DispatchSemaphore(value: 0)

  checkHelperInstallation { isInstalled in
    if isInstalled == false {
      logger.log("Installing helper")
      installHelper(authorized: authorized, installed: installed)
    } else {
      authorized.signal()
      installed.signal()
    }
  }

  _ = authorized.wait(timeout: .now() + 60.0)
  _ = installed.wait(timeout: .now() + 10.0)

  if #available(macOS 12.0, *) {
    let delegate = AppDelegate()
    app.delegate = delegate

    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
  } else {
    print("Only works in macOS 12.0 or newer")
    exit(1)
  }

}

main()

extension CommandLine {
  static var isDevBuild: Bool {
    if let arg = arguments.first(where: { $0.hasPrefix("isDeveloper") }) {
      return arg.contains("=true")
    }
    return false
  }
}
