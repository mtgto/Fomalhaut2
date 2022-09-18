// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxRealm

extension NSTableView {
  func applyChangeset(_ changes: RealmChangeset) {
    beginUpdates()
    removeRows(at: IndexSet(changes.deleted))
    insertRows(at: IndexSet(changes.inserted))
    reloadData(forRowIndexes: IndexSet(changes.updated), columnIndexes: [0, 1, 2])
    endUpdates()
  }
}
