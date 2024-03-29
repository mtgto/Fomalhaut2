// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class CollectionViewHeaderView: NSView, NSCollectionViewElement {
  static let itemSizeIndexKey = "collectionViewitemSizeIndex"
  static let itemSizes: [NSSize] = [
    NSMakeSize(100.125, 153), NSMakeSize(120.15, 183.6), NSMakeSize(133.5, 204),
  ]

  @IBOutlet weak var orderButton: NSPopUpButton!
  @IBOutlet weak var collectionSizeSlider: NSSlider!

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
    self.collectionSizeSlider.integerValue = UserDefaults.standard.integer(
      forKey: CollectionViewHeaderView.itemSizeIndexKey)
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

  @IBAction func resize(_ sender: Any) {
    if let slider = sender as? NSSlider {
      UserDefaults.standard.set(slider.integerValue, forKey: CollectionViewHeaderView.itemSizeIndexKey)
    }
  }
}
