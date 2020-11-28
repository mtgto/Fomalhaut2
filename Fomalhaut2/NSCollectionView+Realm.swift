// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxRealm

extension NSCollectionView {
  func applyChangeset(_ changes: RealmChangeset) {
    performBatchUpdates {
      deleteItems(at: Set(changes.deleted.map { IndexPath(item: $0, section: 0) }))
      insertItems(at: Set(changes.inserted.map { IndexPath(item: $0, section: 0) }))
      reloadItems(at: Set(changes.updated.map { IndexPath(item: $0, section: 0) }))
    } completionHandler: { (finished) in

    }
  }
}
