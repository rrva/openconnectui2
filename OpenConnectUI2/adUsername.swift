import Foundation

let adUsername: String? = {
  do {
    let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
      ".openconnectui2.prefs")

    let data = try Data(contentsOf: url)
    let string = String(data: data, encoding: .utf8)
    return string?.trimmingCharacters(in: .whitespacesAndNewlines)
  } catch {
    logger.log("Could not read username from ~/.openconnectui2.prefs")
    return nil
  }
}()
