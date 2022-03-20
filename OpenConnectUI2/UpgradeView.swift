import Foundation
import SwiftUI

class Upgrade: ObservableObject {
  @Published var progress: Double = 0.0
  @Published var action: String = "Downloading..."
  @Published var message: String = "A new version is available"
  var isRestartButtonVisible: Bool { upgrade.message != "A new version is available" }
}

@available(macOS 12.0, *)
struct UpgradeView: View {
  @ObservedObject
  var upgrade: Upgrade

  var body: some View {
    VStack {
      Text("OpenConnect updater").padding()
      Text(upgrade.message).padding()
      ProgressView(upgrade.action, value: upgrade.progress, total: 100)
      if upgrade.isRestartButtonVisible {
        Button("Restart") {
          NSApplication.shared.terminate(nil)
        }
      }
    }
    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 150, maxHeight: 150).padding(24)
  }
}
