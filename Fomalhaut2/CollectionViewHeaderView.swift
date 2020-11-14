// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class CollectionViewHeaderView: NSView, NSCollectionViewElement {

  @IBOutlet weak var orderButton: NSPopUpButton!

  override func awakeFromNib() {
    self.orderButton.removeAllItems()
    self.orderButton.addItems(withTitles: ["Sort By", "Created", "View count"])
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
