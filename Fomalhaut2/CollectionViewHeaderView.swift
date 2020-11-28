// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class CollectionViewHeaderView: NSView, NSCollectionViewElement {

  @IBOutlet weak var orderButton: NSPopUpButton!

  override func awakeFromNib() {
    self.orderButton.removeAllItems()
    self.orderButton.addItems(withTitles: [
      NSLocalizedString("SortPopupTitle", comment: "Sort by"),
      NSLocalizedString("CreatedAtCaption", comment: "Created"),
      NSLocalizedString("ViewCountCaption", comment: "View count"),
    ])
    // TODO: Restore last selected item
    self.orderButton.item(at: 1)?.state = .on
  }

  @IBAction func setOrder(_ sender: Any) {
    let collectionOrder: CollectionOrder
    let selectedIndex = self.orderButton.indexOfSelectedItem
    switch selectedIndex {
    case 1:
      collectionOrder = .createdAt
    case 2:
      collectionOrder = .readCount
    default:
      log.error("Unknown collection order selected: \(selectedIndex)")
      collectionOrder = .createdAt
    }
    self.orderButton.itemArray.enumerated().forEach { (item) in
      item.element.state = item.offset == selectedIndex ? .on : .off
    }
    NotificationCenter.default.post(
      name: collectionOrderChangedNotificationName, object: nil,
      userInfo: ["order": collectionOrder])
  }
}
