// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRealm

extension NSOutlineView {
  // Rename from extension of NSTableView to avoid compile error:
  // "Overriding declarations in extensions is not supported"
  func applyChangesetForOutlineView(_ changes: RealmChangeset, rootItem: Any?, updatedItems: [Object]) {
    // Support only one root item for now.
    self.beginUpdates()
    self.removeItems(at: IndexSet(changes.deleted), inParent: rootItem, withAnimation: .slideUp)
    self.insertItems(at: IndexSet(changes.inserted), inParent: rootItem, withAnimation: .slideUp)
    updatedItems.forEach { self.reloadItem($0) }
    endUpdates()
  }
}
