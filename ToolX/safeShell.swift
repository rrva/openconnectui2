import Foundation

func safeShellWithArgs(executable: String, args: [String], pipe: Pipe, inputPipe: Pipe? = nil)
  throws -> Process
{
  NSLog("executing \(executable) with \(args)")
  let task = Process()
  task.standardOutput = pipe
  task.standardError = pipe
  if let stdinPipe = inputPipe {
    task.standardInput = stdinPipe
  }
  task.arguments = args
  task.executableURL = URL(fileURLWithPath: executable)

  do {
    try task.run()
  } catch { throw error }
  return task
}

func safeShell(_ command: String, pipe: Pipe, inputPipe: Pipe? = nil) throws -> Process {
  NSLog("executing \(command)")
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
