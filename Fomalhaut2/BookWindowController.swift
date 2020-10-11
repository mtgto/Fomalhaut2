import Cocoa
import RxSwift

class BookWindowController: NSWindowController {

  override func windowDidLoad() {
    super.windowDidLoad()
    log.info("hoge")
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
  }

  override func keyDown(with event: NSEvent) {
    log.info("keyDown \(event)")
  }
}
