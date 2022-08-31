import Foundation

func safeShell(_ command: String, pipe: Pipe, inputPipe: Pipe? = nil) throws -> Process {
  let task = Process()
  task.standardOutput = pipe
  task.standardError = pipe
  if let stdinPipe = inputPipe {
    task.standardInput = stdinPipe
  }
  task.arguments = ["-c", command]
  task.executableURL = URL(fileURLWithPath: "/bin/sh")

  do {
    try task.run()
  } catch { throw error }
  return task
}
