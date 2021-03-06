import Foundation

let userNameMatcher = try! NSRegularExpression(pattern: "^[A-Za-z0-9._\\-]+$")
let hostMatcher = try! NSRegularExpression(pattern: "^[A-Za-z0-9._\\-/:+%?&=]+$")

func doStartOpenConnect(
  localUser: String,
  username: String,
  password: String,
  vpnHost: String,
  withReply reply: @escaping (FileHandle) -> Void
) {

  let pipe = Pipe()
  if !userNameMatcher.matches(localUser) {
    pipe.fileHandleForWriting.write(
      "Invalid characters in localUser: [\(localUser)]\n".data(using: .utf8)!)
    reply(pipe.fileHandleForReading)
    return
  }
  if !userNameMatcher.matches(username) {
    pipe.fileHandleForWriting.write(
      "Invalid characters in username: [\(username)]\n".data(using: .utf8)!)
    reply(pipe.fileHandleForReading)
    return
  }
  if vpnHost.isEmpty {
    pipe.fileHandleForWriting.write("Server not configured in preferences\n".data(using: .utf8)!)
    reply(pipe.fileHandleForReading)
    return
  }
  if !hostMatcher.matches(vpnHost) {
    pipe.fileHandleForWriting.write(
      "Invalid characters in server: [\(vpnHost)]\n".data(using: .utf8)!)
    reply(pipe.fileHandleForReading)
    return
  }
  do {
    let task = try safeShell("route delete -n \(vpnHost) ; pkill openconnect", pipe: pipe)
    task.waitUntilExit()
  } catch {
    NSLog("Failed to kill: \(error)")
  }
  setenv("OPENCONNECT_PASSWORD", String(describing: password), 1)
  setenv("AD_USERNAME", username, 1)
  setenv("LC_MESSAGES", "C", 1)
  setenv("LANG", "C", 1)

  let programPath = Bundle.main.executablePath.unsafelyUnwrapped
  guard let openConnect = locateOpenConnect() else {
    let pipe = Pipe()
    if #available(macOS 10.15.4, *) {
      do {
        let notFound = "openconnect not found. Install it via homebrew: https://brew.sh/"
        try pipe.fileHandleForWriting.write(
          contentsOf:
            notFound.data(using: .utf8)!)
      } catch {
        NSLog("\(error)")
      }
    } else {
      // Fallback on earlier versions
    }
    reply(pipe.fileHandleForReading)
    return
  }
  let command = """
    echo $OPENCONNECT_PASSWORD | \(String(describing: openConnect)) -b  --pid-file /var/run/openconnect.pid -s "\(programPath) vpnc" --setuid=\(localUser) --user=$AD_USERNAME \(vpnHost)
    """

  do {
    NSLog(command)
    let pipe = Pipe()
    let task = try safeShell(command, pipe: pipe)
    reply(pipe.fileHandleForReading)
    task.waitUntilExit()
  } catch {
    NSLog("\(error)")
  }

}
