import Foundation
import SwiftUI

class Logs: ObservableObject {
  @Published var text: String = ""

  public func updateText(msg: String) {
    if msg.isEmpty {
      return
    }
    DispatchQueue.main.async {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "HH:mm:ss"
      let now = Date()
      let lines = msg.split(separator: "\n")
      for line in lines {
        self.text += dateFormatter.string(from: now) + " | " + line + "\n"
      }
    }
  }

  func log(_ msg: String) {
    updateText(msg: msg)
  }
}

@available(macOS 12.0, *)
struct LogView: View {
  @ObservedObject
  var logs: Logs
  var body: some View {
    TextEditor(text: .constant(logs.text))
      .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 600, maxHeight: 600)
      .font(.system(size: 12, design: .monospaced))
  }
}

class Logger {
  @ObservedObject
  var logs = Logs()

  func log(_ msg: String) {
    logs.updateText(msg: msg)
    print(msg)
  }
}
