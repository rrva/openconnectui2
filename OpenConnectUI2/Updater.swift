import Foundation

func getCurrentMillis() -> Int64 {
  Int64(NSDate().timeIntervalSince1970 * 1000)
}

struct PublishedVersion: Decodable {
  var latest: String
  var link: String
}

func newVersionAvailable(logs: Logs, _ block: @escaping (PublishedVersion) -> Void) {
  let runningVersion = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-1") ?? -1
  guard
    let publishedURL = URL(
      string:
        "https://raw.githubusercontent.com/rrva/openconnectui2/main/latest-auto-update.json?foo=\(getCurrentMillis())"
    )
  else {
    return
  }
  var request = URLRequest(url: publishedURL)
  request.httpMethod = "GET"
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")

  let configuration = URLSessionConfiguration.ephemeral
  let session = URLSession(configuration: configuration)
  let task = session.dataTask(
    with: request,
    completionHandler: { data, _, error -> Void in
      if error == nil && data != nil {
        guard
          let publishedVersion = try? JSONDecoder().decode(
            PublishedVersion.self, from: data.unsafelyUnwrapped)
        else {
          return
        }
        let latestVersion = Int(publishedVersion.latest) ?? 0
        if latestVersion > runningVersion {
          logs.log("Latest version: \(latestVersion)")
          logs.log("Running version: \(runningVersion)")
          block(publishedVersion)
        } else {
          logs.log("Latest version: \(latestVersion)")
          logs.log("Running version: \(runningVersion)")
        }
      } else {
        logs.log("\(String(describing: error))")
      }
    })
  task.resume()

}

class Downloader: NSObject, URLSessionTaskDelegate, URLSessionDownloadDelegate {

  var logs: Logs
  var upgrade: Upgrade

  init(logs: Logs, upgrade: Upgrade) {
    self.logs = logs
    self.upgrade = upgrade
    super.init()
  }

  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
  ) {
    if totalBytesExpectedToWrite > 0 {
      let progress = (Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100.0
      let progressStr = String(
        format: "%.2f", progress)
      logs.log("Downloading \(progressStr)%")

      DispatchQueue.main.async { [self] in
        upgrade.progress = progress
      }
    }
  }
  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    logs.log("Download complete \(location)")
    do {
      let resources = try location.resourceValues(forKeys: [.fileSizeKey])
      let fileSize = resources.fileSize!
      try performUpgrade(
        download: FileHandle.init(forReadingFrom: location), downloadSize: fileSize, logs: logs,
        upgrade: upgrade)
    } catch {
      logs.log("Failed upgrade: \(error)")
      return
    }
  }

  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {  // Clean up state, handle errors if there are any

  }

  private lazy var urlSession = URLSession(
    configuration: .default,
    delegate: self,
    delegateQueue: nil)

  func downloadNew(_ link: URL) {
    let downloadTask = urlSession.downloadTask(with: link)
    downloadTask.resume()
  }

}
