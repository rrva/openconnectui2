import Foundation

func doStopOpenConnect(_ reply: (String) -> Void) {
  do {
    let pipe = Pipe()
    let task = try safeShell("pkill openconnect", pipe: pipe)
    pipe.fileHandleForReading.readabilityHandler = { pipe in
      if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
        NSLog(line)
      } else {
        NSLog("Error decoding data: \(pipe.availableData)")
      }
    }
    task.waitUntilExit()
    reply("true")
    NSLog("Disconnected")
  } catch {
    NSLog("\(error)")
  }
}
