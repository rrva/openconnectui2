import Foundation

let localUserNameMatcher = try! NSRegularExpression(pattern: "^[A-Za-z0-9._\\-]+$")
let userNameMatcher = try! NSRegularExpression(pattern: "^[A-Za-z0-9._%+\\-@]+$")
let hostMatcher = try! NSRegularExpression(pattern: "^[A-Za-z0-9._\\-/:+%?=]+$")
let customArgsMatcher = try! NSRegularExpression(pattern: "^[\\p{L}\\p{N}\\s._=,:\\/\\-]+$")

func doStartOpenConnect(
  localUser: String,
  username: String,
  password: String,
  vpnHost: String,
  programPath: String,
  customArgs: String?,
  withReply reply: @escaping (FileHandle) -> Void
) {

  let pipe = Pipe()
  if let args = customArgs {
    if !customArgsMatcher.matches(args) {
      pipe.fileHandleForWriting.write(
        "Invalid characters in custom args: [\(args)]\n".data(using: .utf8)!)
      reply(pipe.fileHandleForReading)
      return
    }
  }
  if !localUserNameMatcher.matches(localUser) {
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
    let task = try safeShell("pkill openconnect", pipe: pipe)
    task.waitUntilExit()
  } catch {
    NSLog("Failed to kill: \(error)")
  }
  setenv("AD_USERNAME", username, 1)
  setenv("LC_MESSAGES", "en_US.UTF-8", 1)

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

  let arguments = [
    "-b", "--pid-file", "/var/run/openconnect.pid", "-s", "\(programPath) vpnc",
    "--setuid=\(localUser)",
    "--useragent=AnyConnect", "--user=\(username)",
  ]
  let extraArguments =
    customArgs?.split(separator: " ", omittingEmptySubsequences: true).map(String.init) ?? []

  do {

    let pipe = Pipe()
    let inputPipe = Pipe()
    let task = try safeShellWithArgs(
      executable: openConnect, args: arguments + extraArguments + [vpnHost], pipe: pipe,
      inputPipe: inputPipe)
    inputPipe.fileHandleForWriting.write(password.data(using: .utf8)!)
    inputPipe.fileHandleForWriting.closeFile()
    reply(pipe.fileHandleForReading)
    task.waitUntilExit()
  } catch {
    NSLog("\(error)")
  }

}
