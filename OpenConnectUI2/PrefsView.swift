import Combine
import Foundation
import SwiftUI

@available(macOS 12.0, *)
struct PrefsView: View {
  @ObservedObject var userSettings: UserSettings
  @State private var openConnectPath: String = ""
  private var logger: Logger?
  init(userSettings: UserSettings, logger: Logger?) {
    self.userSettings = userSettings
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
          .background(userSettings.usernameIsValid ? Color.clear : Color.red.opacity(0.3))
        if !userSettings.usernameIsValid {
          Text(
            "Username can only contain letters, numbers, dots (.), underscores (_), percent (%), plus (+), hyphens (-), and the at (@) symbol."
          )
          .fixedSize(horizontal: false, vertical: true)
          .font(.caption)
          .foregroundColor(.red)
          .padding([.top, .bottom], 2)
        }
        SecureField(text: $userSettings.password, prompt: Text("Password")) {
          Text("VPN password")
            .disableAutocorrection(true)
        }.textFieldStyle(.roundedBorder)
        TextField(text: $userSettings.host, prompt: Text("VPN Gateway host name")) {
          Text("Server")
            .disableAutocorrection(true)
        }.textFieldStyle(.roundedBorder)
          .background(userSettings.hostIsValid ? Color.clear : Color.red.opacity(0.3))
        if !userSettings.hostIsValid {
          Text(
            "Server can only include letters, numbers, dots (.), underscores (_), hyphens (-), slashes (/), colons (:), plus (+), percent (%), question marks (?) and equals (=) signs."
          )
          .fixedSize(horizontal: false, vertical: true)
          .font(.caption)
          .foregroundColor(.red)
          .padding([.top, .bottom], 2)
        }
        Toggle(isOn: $userSettings.customArgsEnabled) {
          Text("Enable Custom Args")
        }
        if userSettings.customArgsEnabled {
          TextField("Custom Arguments", text: $userSettings.customArgs)
            .textFieldStyle(.roundedBorder)
            .background(userSettings.customArgsIsValid ? Color.clear : Color.red.opacity(0.3))
          if !userSettings.customArgsIsValid {
            Text(
              "Custom arguments can only contain letters, numbers, spaces, dots (.), hyphens (-), underscores (_), equals (=), colons (:), commas (,), and slashes (/)."
            )
            .fixedSize(horizontal: false, vertical: true)
            .font(.caption)
            .foregroundColor(.red)
            .padding([.top, .bottom], 2)
          }
        }
      }
    }
    .onDisappear {
      self.userSettings.forceUpdatePassword()
    }
    .frame(minWidth: 100, maxWidth: .infinity, minHeight: 150).padding(24)
  }
}

@available(macOS 12.0, *)
struct PrefsView_Previews: PreviewProvider {
  static var previews: some View {
    PrefsView(userSettings: UserSettings(), logger: nil)
  }
}

extension String {
  func matches(_ regex: String) -> Bool {
    return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
  }
}

class UserSettings: ObservableObject {
  @Published var username: String {
    didSet {
      usernameIsValid = username.matches(usernamePattern)
      if usernameIsValid {
        UserDefaults.standard.set(username, forKey: "username")
        updatePasswordDebounced()
      }

    }
  }

  var host: String {
    didSet {
      hostIsValid = host.matches(hostPattern)
      if hostIsValid {
        UserDefaults.standard.set(host, forKey: "host")
      }
    }
  }

  var customArgs: String {
    didSet {
      customArgsIsValid = customArgs.matches(customArgsPattern)
      if customArgsIsValid {
        UserDefaults.standard.set(customArgs, forKey: "customArgs")
      }
    }
  }

  @Published var password: String {
    didSet {
      updatePasswordDebounced()
    }
  }
  @Published var customArgsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(customArgsEnabled, forKey: "customArgsEnabled")
    }
  }

  @Published var usernameIsValid = true
  @Published var hostIsValid = true
  @Published var customArgsIsValid = true

  private let usernamePattern = "^[A-Za-z0-9._%+\\-@]+$"
  private let hostPattern = "^[A-Za-z0-9._\\-/:+%?=]+$"
  private let customArgsPattern = "^[a-zA-Z0-9\\s.\\-_=,:/]+$"

  private var updatePasswordWorkItem: DispatchWorkItem?
  private let debounceInterval: TimeInterval = 0.5
  private let queue = DispatchQueue(label: "se.rrva.OpenConnectUI2.userSettings")

  init() {
    let username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
    self.username = username
    self.host = UserDefaults.standard.object(forKey: "host") as? String ?? ""
    self.password = getPassword("openconnect", account: username) ?? ""
    self.customArgsEnabled = UserDefaults.standard.bool(forKey: "customArgsEnabled")
    self.customArgs = UserDefaults.standard.string(forKey: "customArgs") ?? ""
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
