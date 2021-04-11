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
    self.collectionMenu.addItem(
      NSMenuItem(
        title: NSLocalizedString("FilterListMenuRename", comment: "Rename"), action: #selector(renameCollection(_:)),
        keyEquivalent: ""))
    self.collectionMenu.addItem(NSMenuItem(title: "Delete", action: #selector(deleteCollection(_:)), keyEquivalent: ""))
    super.init(coder: coder)
    self.collectionMenu.delegate = self
  }

  // MARK: NSMenuDelegate
  override func menu(for event: NSEvent) -> NSMenu? {
    let point = convert(event.locationInWindow, from: nil)
    let clickedRow = self.row(at: point)
    if let collection = self.item(atRow: clickedRow) as? Collection {
      self.selectedCollection = collection
      self.collectionMenu.item(at: 1)?.title = String(
        format: NSLocalizedString("FilterListMenuDelete", comment: "Delete %@"), collection.name)
      return self.collectionMenu
    } else {
      self.selectedCollection = nil
    }
    return nil
  }

  // MARK: - NSMenu
  @objc func renameCollection(_ sender: Any) {
    if let collection = self.selectedCollection {
      NotificationCenter.default.post(
        name: collectionStartRenamingNotificationName, object: nil, userInfo: ["collection": collection])
      self.selectedCollection = nil
    }
  }

  @objc func deleteCollection(_ sender: Any) {
    if let collection = self.selectedCollection {
      // To avoid crash, you MUST remove items from NSOutlineView before delete.
      NotificationCenter.default.post(
        name: collectionDeleteNotificationName, object: nil, userInfo: ["collection": collection])
      self.selectedCollection = nil
    }
  }

  // MARK: NSMenuItemValidation
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    // All collection can be deleted
    return true
  }

  // MARK: NSResponder
  override func becomeFirstResponder() -> Bool {
    // To force selected cell color to dark
    return false
  }
}
