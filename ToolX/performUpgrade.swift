import Foundation

@available(macOS 10.15.4, *)
func performUpgrade(
  download: FileHandle, downloadSize: Int, appLocation: URL, pid: Int32, user: UInt32,
  withReply reply: @escaping (FileHandle) -> Void
) {

  let replyPipe = Pipe()

  do {
    let destinationURL: URL = appLocation
    let temporaryDirectoryURL =
      try FileManager.default.url(
        for: .itemReplacementDirectory,
        in: .userDomainMask,
        appropriateFor: destinationURL,
        create: true)

    if let unpackResult = unpack(
      download: download, downloadSize: downloadSize, temporaryDirectoryURL: temporaryDirectoryURL
    ) {
      replyData(replyPipe: replyPipe, context: "Unpack", data: unpackResult, reply: reply)
      return
    }

    guard
      let checkSignatureOutput = checkAppSignature(temporaryDirectoryURL: temporaryDirectoryURL)
    else {
      replyString(
        replyPipe: replyPipe,
        context: "Check signature",
        error: "Could not read output", reply: reply)
      return
    }
    guard let appSignature = String(data: checkSignatureOutput, encoding: .utf8) else {
      replyString(
        replyPipe: replyPipe,
        context: "Check signature",
        error: "Output malformed", reply: reply)
      return
    }

    let devSignature =
      "Authority=Developer ID Application: Ragnar Rova (3563RJWBQP)\nAuthority=Developer ID Certification Authority\nAuthority=Apple Root CA\n"

    let notarySignature =
      "Authority=Apple Development: ragnar.rova@gmail.com (U34QC433V8)\nAuthority=Apple Worldwide Developer Relations Certification Authority\nAuthority=Apple Root CA\n"

    if appSignature != devSignature && appSignature != notarySignature {
      replyString(
        replyPipe: replyPipe, context: "Check signature",
        error: "Code signature does not match, not upgrading: \(appSignature)", reply: reply)
      return
    }

    NSLog("App signature matches")
    if appLocation.pathComponents.contains("Xcode") {
      replyString(
        replyPipe: replyPipe,
        context: "Xcode check",
        error: "Detected Xcode run, skipping upgrade", reply: reply)
      return
    }
    NSLog("Code signature matches: \(appSignature)")

    let oldAppLocation = "\(appLocation.deletingPathExtension().path  ) (12345).app"
    let moveResult = moveOldApp(
      appLocation: appLocation, oldAppLocation: oldAppLocation,
      temporaryDirectoryURL: temporaryDirectoryURL)

    if moveResult != nil {
      replyData(replyPipe: replyPipe, context: "Move files", data: moveResult, reply: reply)
      return
    }
    replyString(
      replyPipe: replyPipe, context: "Upgrade", error: "Upgrade complete", reply: reply)
    restartAppOnOldAppExit(pid: pid, appLocation: appLocation, user: user)

  } catch {
    replyString(
      replyPipe: replyPipe, context: "General upgrade error", error: "Upgrade error: \(error)",
      reply: reply)
  }
}

@available(macOS 10.15.4, *)
func replyString(
  replyPipe: Pipe, context: String, error: String, reply: @escaping (FileHandle) -> Void
) {
  replyData(replyPipe: replyPipe, context: context, data: error.data(using: .utf8), reply: reply)
}

@available(macOS 10.15.4, *)
func replyData(
  replyPipe: Pipe, context: String, data: Data?, reply: @escaping (FileHandle) -> Void
) {
  do {
    if data == nil {
      replyString(
        replyPipe: replyPipe, context: context, error: "Unknown error, data==nil", reply: reply)
    }
    try replyPipe.fileHandleForWriting.write(
      contentsOf: ("\(context): ".data(using: .utf8) ?? "unknown".data(using: .utf8))!)
    try replyPipe.fileHandleForWriting.write(contentsOf: data.unsafelyUnwrapped)
    reply(replyPipe.fileHandleForReading)
    try replyPipe.fileHandleForWriting.close()
    try replyPipe.fileHandleForReading.close()
  } catch {
    replyString(replyPipe: replyPipe, context: context, error: "\(error)", reply: reply)
  }
}
