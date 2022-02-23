import Foundation
import SwiftUI

let license = (Bundle.main.infoDictionary?["license"] as! String).deletingPrefix("string ")

struct LicenseView: View {
  @EnvironmentObject private var visibility: AboutViewVisibility
  var body: some View {
    Text(license)
      .multilineTextAlignment(.leading).font(.system(size: 10))
  }

}

extension String {
  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(self.dropFirst(prefix.count))
  }
}
