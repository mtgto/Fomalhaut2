// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxRealm

extension NSCollectionView {
  func applyChangeset(_ changes: RealmChangeset) {
    // Convert the selection to the indexes after the changes (deleted/inserted items shift the indexes).
    let deleted = changes.deleted.sorted()
    let inserted = changes.inserted.sorted()
    let selection = Set(
      self.selectionIndexPaths.compactMap { indexPath -> IndexPath? in
        let old = indexPath.item
        if deleted.contains(old) { return nil }
        var new = old - deleted.filter { $0 < old }.count
        for index in inserted where index <= new {
          new += 1
        }
        return IndexPath(item: new, section: indexPath.section)
      })
    self.animator().performBatchUpdates {
      deleteItems(at: Set(changes.deleted.map { IndexPath(item: $0, section: 0) }))
      insertItems(at: Set(changes.inserted.map { IndexPath(item: $0, section: 0) }))
      reloadItems(at: Set(changes.updated.map { IndexPath(item: $0, section: 0) }))
    } completionHandler: { (finished) in
      // NSCollectionView may keep or shift the selection by itself, so reset it explicitly.
      self.deselectAll(nil)
      self.selectItems(at: selection, scrollPosition: [])
    }
  }
}
