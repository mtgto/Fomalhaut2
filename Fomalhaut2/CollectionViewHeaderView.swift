// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class CollectionViewHeaderView: NSView, NSCollectionViewElement {

  @IBOutlet weak var orderButton: NSPopUpButton!

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // Drawing code here.
    //    NSColor.red.set()
    //    NSBezierPath.fill(dirtyRect)
  }

}
