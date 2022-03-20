import Foundation

func findOpenConnectPid() -> pid_t {
  let fileContent = try? String(contentsOf: URL(fileURLWithPath: "/var/run/openconnect.pid"))
  if let content = fileContent {
    let pid = pid_t(content.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    return pid
  }
  return 0
}
