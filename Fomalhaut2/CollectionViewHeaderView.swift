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
      NSLocalizedString("NameCaption", comment: "Name"),
    ])
    let collectionOrder = CollectionOrder(
      rawValue: UserDefaults.standard.string(forKey: BookCollectionViewController.collectionOrderKey)!)!
    self.orderButton.item(at: self.menuItemIndex(collectionOrder: collectionOrder))!.state = .on
  }

  private func menuItemIndex(collectionOrder: CollectionOrder) -> Int {
    switch collectionOrder {
    case .createdAt:
      return 1
    case .readCount:
      return 2
    case .name:
      return 3
    }
  }

  @IBAction func setOrder(_ sender: Any) {
    let collectionOrder: CollectionOrder
    let selectedIndex = self.orderButton.indexOfSelectedItem
    switch selectedIndex {
    case 1:
      collectionOrder = .createdAt
    case 2:
      collectionOrder = .readCount
    case 3:
      collectionOrder = .name
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
