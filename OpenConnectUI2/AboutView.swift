import Foundation
import SwiftUI

class About: ObservableObject {
  @Published var showLicense: Bool = false
}

class AboutViewVisibility: ObservableObject {
  @Published var showLicense: Bool
  init(showLicense: Bool) {
    self.showLicense = showLicense

  }
}

struct AboutView: View {
  @EnvironmentObject private var visibility: AboutViewVisibility
  var body: some View {
    VStack(spacing: 16) {
      if !visibility.showLicense {
        AboutView2().environmentObject(visibility)
      }
      if visibility.showLicense {
        Spacer()
        LicenseView().environmentObject(visibility)
        Spacer()
      }
    }.frame(minWidth: 400, maxWidth: .infinity, minHeight: 400, maxHeight: 400)
  }
}

struct AboutView2: View {
  @EnvironmentObject private var visibility: AboutViewVisibility

  let version = String(
    describing: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion").unsafelyUnwrapped)

  var body: some View {
    Text(
      """
      **OpenConnectUI2 version \(version)**

      A Mac OSX UI for [OpenConnect VPN client](https://www.infradead.org/openconnect/)

      Standing on the shoulders of giants:

      Thank you to the OpenConnect authors for the vpn client

      OpenConnect questions:

      [http://www.infradead.org/openconnect/mail.html](http://www.infradead.org/openconnect/mail.html)

      Copyright © 2022 Ragnar Rova

      [Source code on GitHub](https://github.com/rrva/openconnectui2)
      """
    ).multilineTextAlignment(.center).padding(16)
    Button(action: {
      visibility.showLicense = true
    }) {
      Text("License")
    }.padding(16)
  }

  struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
      AboutView()
    }
  }
}
