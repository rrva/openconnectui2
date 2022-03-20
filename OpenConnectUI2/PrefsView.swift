import Foundation
import SwiftUI

@available(macOS 12.0, *)
struct PrefsView: View {
  @ObservedObject var userSettings = UserSettings()
  @State private var openConnectPath: String = ""
  private var logger: Logger
  init(logger: Logger) {
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
    }.frame(minWidth: 100, maxWidth: .infinity, minHeight: 150, maxHeight: 150).padding(24)
  }
}

class UserSettings: ObservableObject {
  @Published var username: String {
    didSet {
      UserDefaults.standard.set(username, forKey: "username")
    }
  }

  @Published var host: String {
    didSet {
      UserDefaults.standard.set(host, forKey: "host")
    }
  }

  @Published var password: String {
    didSet {
      let result = addOrUpdatePassword("openconnect", account: username, password: password)
      if result == false {
        logger.log("Failed adding or updating password")
      } else {
        logger.log("Password updated")
      }
    }
  }

  init() {
    let usernameStr = UserDefaults.standard.object(forKey: "username") as? String ?? ""
    let hostStr = UserDefaults.standard.object(forKey: "host") as? String ?? ""
    username = usernameStr
    host = hostStr
    password = getPassword("openconnect", account: usernameStr) ?? ""
  }
}
