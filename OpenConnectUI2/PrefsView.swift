import Combine
import Foundation
import SwiftUI

@available(macOS 12.0, *)
struct PrefsView: View {
  @ObservedObject var userSettings = UserSettings()
  @State private var openConnectPath: String = ""
  private var logger: Logger?
  init(logger: Logger?) {
    self.logger = logger
  }

  func getUserSettings() -> UserSettings {
    userSettings
  }

  var shouldShowPrompt: Bool {
    userSettings.username == ""
  }

  var body: some View {
    VStack {
      Text("Configure these settings and then retry connecting").padding()
      Form {
        TextField(text: $userSettings.username, prompt: Text("Usually your AD username")) {
          Text("Username")
            .disableAutocorrection(true)
        }.textFieldStyle(.roundedBorder)
        SecureField(text: $userSettings.password, prompt: Text("Password")) {
          Text("VPN password")
            .disableAutocorrection(true)
        }.textFieldStyle(.roundedBorder)
        TextField(text: $userSettings.host, prompt: Text("VPN Gateway host name")) {
          Text("Server")
            .disableAutocorrection(true)
        }.textFieldStyle(.roundedBorder)
        Spacer().frame(idealHeight: 0)
      }
    }
    .onDisappear {
      self.userSettings.forceUpdatePassword()
    }
    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 150, maxHeight: 150).padding(24)
  }
}

@available(macOS 12.0, *)
struct PrefsView_Previews: PreviewProvider {
  static var previews: some View {
    PrefsView(logger: nil)
  }
}

class UserSettings: ObservableObject {
  @Published var username: String {
    didSet {
      UserDefaults.standard.set(username, forKey: "username")
      updatePasswordDebounced()
    }
  }
  @Published var host: String {
    didSet {
      UserDefaults.standard.set(host, forKey: "host")
    }
  }
  @Published var password: String {
    didSet {
      updatePasswordDebounced()
    }
  }

  private var updatePasswordWorkItem: DispatchWorkItem?
  private let debounceInterval: TimeInterval = 0.5
  private let queue = DispatchQueue(label: "com.yourapp.userSettings")

  init() {
    let username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
    self.username = username
    self.host = UserDefaults.standard.object(forKey: "host") as? String ?? ""
    self.password = getPassword("openconnect", account: username) ?? ""
  }

  private func updatePasswordDebounced() {
    updatePasswordWorkItem?.cancel()

    let workItem = DispatchWorkItem { [weak self] in
      guard let self = self else { return }
      let result = addOrUpdatePassword(
        "openconnect", account: self.username, password: self.password)
      if result {
        logger.log("Password updated")
      } else {
        logger.log("Failed to update password")
      }
    }

    updatePasswordWorkItem = workItem
    queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
  }

  func forceUpdatePassword() {
    queue.sync {
      updatePasswordWorkItem?.perform()
      updatePasswordWorkItem?.cancel()
      updatePasswordWorkItem = nil
    }
  }
}
