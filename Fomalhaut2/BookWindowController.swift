// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class BookWindowController: NSWindowController {

  override func windowDidLoad() {
    super.windowDidLoad()
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 49 {  // space
      let bookViewController = self.contentViewController as! SpreadPageViewController
      if event.modifierFlags.contains(.shift) {
        bookViewController.decrementPage()
      } else {
        bookViewController.incrementPage()
      }
    } else {
      log.info("keyDown: \(event.keyCode)")
    }
  }
}
