// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

let collectionOrderChangedNotificationName = Notification.Name("collectionOrderChanged")

class BookCollectionView: NSCollectionView {
  private(set) var selectedIndexPath: IndexPath?

  override func menu(for event: NSEvent) -> NSMenu? {
    let point = self.convert(event.locationInWindow, from: nil)
    guard let indexPath = self.indexPathForItem(at: point) else {
      return nil
    }
    self.selectedIndexPath = indexPath
    self.deselectAll(nil)
    self.selectItems(at: [indexPath], scrollPosition: .nearestVerticalEdge)
    return super.menu(for: event)
  }

  override func mouseDown(with event: NSEvent) {
    if event.clickCount == 2 {
      let locationInView = convert(event.locationInWindow, from: nil)
      guard let path = indexPathForItem(at: locationInView) else {
        return
      }
      if let bookCollectionViewController = self.delegate as? BookCollectionViewController {
        bookCollectionViewController.openCollectionViewBook(path)
      }
    }
    super.mouseDown(with: event)
  }
}
