// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class BookCollectionView: NSCollectionView {
  private(set) var selectedIndexPath: IndexPath?

  override func menu(for event: NSEvent) -> NSMenu? {
    let locationInView = convert(event.locationInWindow, from: nil)
    guard let path = indexPathForItem(at: locationInView) else {
      return nil
    }
    self.selectedIndexPath = path
    self.deselectAll(nil)
    self.selectItems(at: [path], scrollPosition: .nearestVerticalEdge)
    return super.menu(for: event)
  }
}
