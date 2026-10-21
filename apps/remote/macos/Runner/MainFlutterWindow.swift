import Cocoa
import FlutterMacOS

/// The remote as a menu-bar panel: a small borderless window that drops down
/// from the status item and hides when it loses focus.
class MainFlutterWindow: NSWindow {
  static let panelSize = NSSize(width: 390, height: 760)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)

    styleMask = [.titled, .fullSizeContentView]
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isMovableByWindowBackground = true
    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true
    level = .floating
    collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    backgroundColor = NSColor(red: 0.043, green: 0.047, blue: 0.063, alpha: 1)
    setContentSize(Self.panelSize)
    isReleasedWhenClosed = false

    super.awakeFromNib()
    orderOut(nil)
  }

  override var canBecomeKey: Bool { true }

  override func resignKey() {
    super.resignKey()
    orderOut(nil)
  }
}
