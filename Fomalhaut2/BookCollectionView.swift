// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

let collectionOrderChangedNotificationName = Notification.Name("collectionOrderChanged")

class BookCollectionView: NSCollectionView {
  override func mouseDown(with event: NSEvent) {
    defer {
      super.mouseDown(with: event)
    }
    if event.clickCount == 2 {
      let locationInView = convert(event.locationInWindow, from: nil)
      guard let path = indexPathForItem(at: locationInView) else {
        return
      }
      if let bookCollectionViewController = self.delegate as? BookCollectionViewController {
        bookCollectionViewController.openCollectionViewBook(path)
      }
    }
  }

  override func rightMouseDown(with event: NSEvent) {
    if event.clickCount == 1 {
      let locationInView = convert(event.locationInWindow, from: nil)
      guard let path = indexPathForItem(at: locationInView) else {
        return super.rightMouseDown(with: event)
      }
      if !self.selectionIndexPaths.contains(path) {
        self.deselectAll(nil)
        self.selectItems(at: [path], scrollPosition: [])
      }
    }
    super.rightMouseDown(with: event)
  }
}
