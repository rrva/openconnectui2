import Cocoa
import Foundation
import Network
import OSAKit
import ServiceManagement
import SwiftUI
import ToolX

@available(macOS 12.0, *)
class AppDelegate: NSObject, NSApplicationDelegate {

  var logWindowController: NSWindowController!
  var prefsWindowController: NSWindowController!
  var upgradeWindowController: NSWindowController!
  var aboutWindowController: NSWindowController!
  var licenseWindowController: NSWindowController!

  let prefsView = PrefsView(logger: logger)

  private var statusItem: NSStatusItem!

  private var concurrentQueue: DispatchQueue!

  let checkForUpgradesTimer = DispatchSource.makeTimerSource(
    flags: [], queue: DispatchQueue.global(qos: .background))

  func applicationDidFinishLaunching(_: Notification) {
    concurrentQueue = DispatchQueue(
      label: "ConcurrentQueue", qos: .default, attributes: .concurrent)
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem.button {
      button.image = NSImage(
        systemSymbolName: "shield.lefthalf.filled", accessibilityDescription: "0")
    }

    setupMenus()
    checkForUpgradesTimer.schedule(
      deadline: DispatchTime.now(), repeating: DispatchTimeInterval.seconds(3600))
    checkForUpgradesTimer.setEventHandler(handler: {
      self.checkForUpgrade()
    })
    checkForUpgradesTimer.resume()
  }

  func setupMenus() {
    let menu = NSMenu()

    let connectMenuItem = NSMenuItem(
      title: "Connect", action: #selector(didTapConnect), keyEquivalent: "c")
    menu.addItem(connectMenuItem)

    let disconnectMenuItem = NSMenuItem(
      title: "Disconnect", action: #selector(didTapDisconnect), keyEquivalent: "d")
    menu.addItem(disconnectMenuItem)

    let logsMenuItem = NSMenuItem(title: "Logs", action: #selector(didTapLogs), keyEquivalent: "l")
    menu.addItem(logsMenuItem)

    let prefsMenuItem = NSMenuItem(
      title: "Preferences", action: #selector(didTapPrefs), keyEquivalent: "p")
    menu.addItem(prefsMenuItem)

    let aboutMenuItem = NSMenuItem(
      title: "About", action: #selector(didTapAbout), keyEquivalent: "a")
    menu.addItem(aboutMenuItem)

    menu.addItem(NSMenuItem.separator())

    menu.addItem(
      NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem.menu = menu
  }

  func log(_ msg: String) {
    logger.logs.updateText(msg: msg)
    print(msg)
  }

  private func changeStatusBarButton(symbolName: String, description: String) {
    if let button = statusItem.button {
      let view = statusItem.button!
      view.subviews.forEach { $0.layer!.removeAllAnimations() }
      view.layer!.removeAllAnimations()
      button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
    }
  }

  @objc func didTapConnect() {
    let host = prefsView.getUserSettings().host
    let adUserName = prefsView.getUserSettings().username
    if adUserName == "" || host == "" {
      if prefsWindowController == nil {
        prefsWindowController = WindowController(hostedView: PrefsView(logger: logger))
      }
      prefsWindowController.showWindow(nil)
      DispatchQueue.main.async {
        NSApp.activate(ignoringOtherApps: true)
        self.prefsWindowController.window?.center()
        self.prefsWindowController.window?.makeKeyAndOrderFront(nil)
      }
      return
    }
    let openConnectPassword = getPassword("openconnect", account: adUserName)
    if openConnectPassword == nil {
      log("Failed to read openconnect password from keychain")
      return
    }

    changeStatusBarButton(symbolName: "hourglass", description: "connecting")

    animateStatusBar(statusItem: statusItem)

    let username = NSUserName()

    concurrentQueue.async {

      self.log("Initiating connection")
      removeDNSAndVPNInterface()
      startOpenConnect(
        localUser: username,
        username: adUserName,
        password: openConnectPassword.unsafelyUnwrapped,
        host: host

      ) { result in
        if result == true {
          DispatchQueue.main.async {
            self.changeStatusBarButton(symbolName: "lock.shield.fill", description: "connected")
          }
        } else {
          DispatchQueue.main.async {
            self.changeStatusBarButton(symbolName: "shield.slash", description: "disconnected")
          }
        }

      }

    }
  }

  @objc func didTapDisconnect() {
    stopOpenConnect()
    removeDNSAndVPNInterface()
    killHelper()
    log("Disconnect")
    changeStatusBarButton(symbolName: "shield.slash", description: "disconnected")
  }

  @objc func didTapLogs() {
    if logWindowController == nil {
      logWindowController = WindowController(
        hostedView: LogView(logs: logger.logs), resizable: true)
    }
    logWindowController.showWindow(nil)
    logWindowController.window?.center()

    NSApp.activate(ignoringOtherApps: true)
    logWindowController.window?.makeKeyAndOrderFront(nil)
  }

  @objc func didTapPrefs() {
    if prefsWindowController == nil {
      prefsWindowController = WindowController(hostedView: PrefsView(logger: logger))
    }
    prefsWindowController.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
    self.prefsWindowController.window?.center()
    self.prefsWindowController.window?.makeKeyAndOrderFront(nil)
  }

  @objc func didTapAbout() {
    aboutViewVisibility.showLicense = false
    if aboutWindowController == nil {
      aboutWindowController = WindowController(
        hostedView: AboutView().environmentObject(aboutViewVisibility))
    }
    aboutWindowController.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
    self.aboutWindowController.window?.center()
    self.aboutWindowController.window?.makeKeyAndOrderFront(nil)
  }

  func applicationWillTerminate(_: Notification) {
    stopOpenConnect()
  }

  func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
    true
  }

  func checkForUpgrade() {
    newVersionAvailable(logs: logger.logs) { version in
      DispatchQueue.main.async {
        if self.upgradeWindowController == nil {
          self.upgradeWindowController = WindowController(hostedView: UpgradeView(upgrade: upgrade))
        }
        NSApp.activate(ignoringOtherApps: true)
        self.upgradeWindowController.window?.center()
        self.upgradeWindowController.window?.makeKeyAndOrderFront(nil)
      }
      let downloader = Downloader(logs: logger.logs, upgrade: upgrade)
      self.log("New version available \(version)")
      guard let url = URL(string: version.link) else {
        return
      }
      downloader.downloadNew(url)
    }
  }

}

let aboutViewVisibility = AboutViewVisibility(showLicense: false)
let about = About()
let logger = Logger()
let upgrade = Upgrade()
