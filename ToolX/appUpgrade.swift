import Foundation

@available(macOS 10.15.4, *)
func restartAppOnOldAppExit(pid: Int32, appLocation: URL, user: UInt32) {
  let restartPipe = Pipe()

  let restartCommand = """
    while /bin/kill -0 \(pid) >&/dev/null ; \
    do \
      sleep 0.1 ; \
    done && \
    sudo -i -u \\#\(user) open "\(appLocation.path)"
    """
  DispatchQueue.global(qos: .background).async {
    do {

      let restartTask = try safeShell(restartCommand, pipe: restartPipe)
      restartTask.waitUntilExit()
      let restartOutput = try restartPipe.fileHandleForReading.readToEnd()
      NSLog("\(String(describing: restartOutput?.debugDescription))")
    } catch {
      NSLog("\(error)")
    }

  }
}

@available(macOS 10.15.4, *)
func moveOldApp(appLocation: URL, oldAppLocation: String, temporaryDirectoryURL: URL) -> Data? {
  let moveCommands = """
    mv -v "\(appLocation.path)" "\(oldAppLocation)" && \
    mv -v "\(temporaryDirectoryURL.appendingPathComponent("OpenConnectUI2.app").path)" "\(appLocation.path)"
    """
  let movePipe = Pipe()
  do {
    let moveTask = try safeShell(moveCommands, pipe: movePipe)
    moveTask.waitUntilExit()
    let status = moveTask.terminationStatus
    guard let moveResult = try movePipe.fileHandleForReading.readToEnd() else {
      return "Failed reading move result".data(using: .utf8)
    }
    if status != 0 {
      return moveResult
    }
    NSLog("Moving files: \(String(data: moveResult, encoding: .utf8).unsafelyUnwrapped)")
    try FileManager.default.trashItem(
      at: URL(fileURLWithPath: oldAppLocation), resultingItemURL: nil)
    return nil
  } catch {
    return "Failed moving files \(error)".data(using: .utf8)
  }
}

func checkAppSignature(temporaryDirectoryURL: URL) -> Data? {
  let checkSignatureCommand = """
    codesign --display --verbose=2 "\(temporaryDirectoryURL.path)/OpenConnectUI2.app" 2>&1 | egrep ^Authority
    """

  let checkSignaturePipe = Pipe()
  do {
    let checkSignatureTask = try safeShell(checkSignatureCommand, pipe: checkSignaturePipe)
    checkSignatureTask.waitUntilExit()

    if #available(macOS 10.15.4, *) {
      return try checkSignaturePipe.fileHandleForReading.readToEnd()
    } else {
      return nil
    }
  } catch {
    return "Failed checking signature: \(error)".data(using: .utf8)
  }
}

@available(macOS 10.15.4, *)
func unpack(download: FileHandle, downloadSize: Int, temporaryDirectoryURL: URL) -> Data? {
  let temporaryFilename = ProcessInfo().globallyUniqueString
  let temporaryFileURL =
    temporaryDirectoryURL.appendingPathComponent(temporaryFilename)

  do {
    let downloadedFileContents = try download.read(upToCount: downloadSize)
    try downloadedFileContents?.write(to: temporaryFileURL)

    let unpackCommand = """
      cd "\(temporaryDirectoryURL.path)" && \
      unzip -qq "\(temporaryFileURL.path)" && \
      xattr -d -r com.apple.quarantine OpenConnectUI2.app
      """

    let unpackPipe = Pipe()
    let unpackTask = try safeShell(unpackCommand, pipe: unpackPipe)
    unpackTask.waitUntilExit()
    return try unpackPipe.fileHandleForReading.readToEnd()
  } catch {
    return "Failed unpacking: \(error)".data(using: .utf8)
  }
}
