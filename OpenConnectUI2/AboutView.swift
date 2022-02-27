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
    VStack {
      if !visibility.showLicense {
        FirstAboutView().environmentObject(visibility)
      }
      if visibility.showLicense {
        Spacer()
        LicenseView().environmentObject(visibility)
        Spacer()
      }
    }.frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: 400)
  }
}

struct FirstAboutView: View {
  @EnvironmentObject private var visibility: AboutViewVisibility

  var body: some View {
    VStack(alignment: .center, spacing: 30) {
      Spacer()
      Text("OpenConnectUI2").font(.largeTitle)
      HStack(alignment: .top, spacing: 20) {
        VStack {
          appImage().padding(10)
          Text("version \(version)")
        }
        aboutText

      }
      Button(action: {
        visibility.showLicense = true
      }) {
        Text("License")

      }
      Spacer()
    }

  }

}

let version = String(
  describing: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion").unsafelyUnwrapped)

let aboutText = Text(
  """
  A Mac OSX UI for [OpenConnect VPN client](https://www.infradead.org/openconnect/)

  Standing on the shoulders of giants:

  Thank you to the OpenConnect authors for the vpn client!

  For OpenConnect questions please go to:

  [http://www.infradead.org/openconnect/mail.html](http://www.infradead.org/openconnect/mail.html)

  [Source code on GitHub](https://github.com/rrva/openconnectui2)

  © 2022 Ragnar Rova
  """
)

func appIconImageRep() -> NSImageRep {
  let appIconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns")!
  let appIcon = NSImage(contentsOfFile: appIconPath)
  let images = appIcon!.representations.sorted(by: { (a: NSImageRep, b: NSImageRep) -> Bool in
    return a.pixelsHigh < b.pixelsHigh
  })
  return images[images.endIndex - 1]

}

let bestImage = appIconImageRep()

func appImage() -> Image {
  let image: NSImage = NSImage(size: bestImage.size)
  image.addRepresentation(bestImage)
  return Image(nsImage: image)
}
