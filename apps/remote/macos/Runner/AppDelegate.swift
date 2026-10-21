import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var statusItem: NSStatusItem?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = item.button {
      button.image = NSImage(systemSymbolName: "tv", accessibilityDescription: "TV Control")
      button.target = self
      button.action = #selector(togglePanel(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    statusItem = item
    super.applicationDidFinishLaunching(notification)
  }

  private var panel: NSWindow? { mainFlutterWindow }

  @objc private func togglePanel(_ sender: NSStatusBarButton) {
    if NSApp.currentEvent?.type == .rightMouseUp {
      let menu = NSMenu()
      menu.addItem(withTitle: "Salir de TV Control", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
      statusItem?.menu = menu
      sender.performClick(nil)
      statusItem?.menu = nil
      return
    }
    guard let panel else { return }
    if panel.isVisible {
      panel.orderOut(nil)
      return
    }
    if let buttonWindow = sender.window {
      let anchor = buttonWindow.convertToScreen(sender.convert(sender.bounds, to: nil))
      let size = panel.frame.size
      var origin = NSPoint(x: anchor.midX - size.width / 2, y: anchor.minY - size.height - 6)
      if let screen = buttonWindow.screen?.visibleFrame {
        origin.x = min(max(origin.x, screen.minX + 8), screen.maxX - size.width - 8)
      }
      panel.setFrameOrigin(origin)
    }
    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    true
  }
}
