// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRealm
import RxSwift

class FilterListView: NSOutlineView, NSMenuDelegate {
  private let collectionMenu: NSMenu
  private var selectedCollection: Collection? = nil

  required init?(coder: NSCoder) {
    self.collectionMenu = NSMenu(title: "Collection")
    self.collectionMenu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteCollection(_:)), keyEquivalent: ""))
    super.init(coder: coder)
    self.collectionMenu.delegate = self
  }

  // Dirty hack: select initially first child of NSOutlineView
  // https://gist.github.com/mrjjwright/218405
  // It is easy to select first parent of NSOutlineView (index == 0)
  override func becomeFirstResponder() -> Bool {
    if self.numberOfSelectedRows == 0 {
      self.selectRowIndexes(IndexSet([1]), byExtendingSelection: false)
    }
    return super.becomeFirstResponder()
  }

  // MAKR: NSMenuDelegate
  override func menu(for event: NSEvent) -> NSMenu? {
    let point = convert(event.locationInWindow, from: nil)
    let clickedRow = self.row(at: point)
    if let collection = self.item(atRow: clickedRow) as? Collection {
      self.selectedCollection = collection
      self.collectionMenu.item(at: 0)?.title = String(
        format: NSLocalizedString("FilterListMenuDelete", comment: "Delete %@"), collection.name)
      return self.collectionMenu
    } else {
      self.selectedCollection = nil
    }
    return nil
  }

  // MARK: - NSMenu
  @objc func deleteCollection(_ sender: Any) {
    if let collection = self.selectedCollection {
      // To avoid crash, you MUST remove items from NSOutlineView before delete.
      NotificationCenter.default.post(
        name: collectionWillDeleteNotificationName, object: nil, userInfo: ["collection": collection])
      self.selectedCollection = nil
      do {
        let realm = try Realm()
        try realm.write {
          realm.delete(collection)
        }
      } catch {
        log.error("Error while deleting a collection \(collection.name): \(error)")
      }
    }
  }

  // MARK: NSMenuItemValidation
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    // All collection can be deleted
    return true
  }
}
