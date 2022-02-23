import Cocoa
import Foundation
import SwiftUI

class WindowController<HostedView: View>: NSWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    window?.delegate = self
  }

  convenience init(hostedView: HostedView, resizable: Bool = false) {
    self.init(
      window: NSWindow(
        contentRect: NSRect(
          x: 100, y: 100,
          width: NSScreen.main!.frame.width / 4,
          height: NSScreen.main!.frame.height / 2),
        styleMask: resizable ? .defaultResizableWindow : .defaultWindow,
        backing: .buffered,
        defer: false))

    window?.contentView = NSHostingView(rootView: hostedView)
    window?.delegate = self
  }

  private func windowDidMiniaturize(notification _: NSNotification) {}

  private func windowWillClose(notification _: NSNotification) {

    aboutViewVisibility.showLicense = false
  }
}

extension NSWindow.StyleMask {
  static var defaultWindow: NSWindow.StyleMask {
    var styleMask: NSWindow.StyleMask = .closable
    styleMask.formUnion(.titled)
    styleMask.formUnion(.miniaturizable)
    return styleMask
  }

  static var defaultResizableWindow: NSWindow.StyleMask {
    var styleMask: NSWindow.StyleMask = .closable
    styleMask.formUnion(.titled)
    styleMask.formUnion(.resizable)
    styleMask.formUnion(.miniaturizable)
    return styleMask
  }
}
