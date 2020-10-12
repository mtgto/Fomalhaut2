import Cocoa
import RxSwift

class BookWindowController: NSWindowController {

  override func windowDidLoad() {
    super.windowDidLoad()
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 49 {  // space
      if event.modifierFlags.contains(.shift) {
        if let bookViewController = self.contentViewController as? SpreadPageViewController {
          bookViewController.decrementPage()
        }
      } else {
        if let bookViewController = self.contentViewController as? SpreadPageViewController {
          bookViewController.incrementPage()
        }
      }
    } else {
      log.info("keyDown: \(event.keyCode)")
    }
  }
}
