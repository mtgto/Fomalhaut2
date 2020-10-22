// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class BookCollectionViewItem: NSCollectionViewItem {

  override var isSelected: Bool {
    didSet {
      self.view.layer?.borderWidth = isSelected ? 3.0 : 0.0
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    view.wantsLayer = true
    view.layer?.borderWidth = 0.0
    view.layer?.cornerRadius = 8.0
    view.layer?.borderColor = NSColor.selectedControlColor.cgColor
  }
}
