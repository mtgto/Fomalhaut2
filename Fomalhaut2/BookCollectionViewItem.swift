// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class BookCollectionViewItem: NSCollectionViewItem {
  // IBOutlet imageView might be nil when NSCollectionViewItem is created by "NSCollectionView.makeItem"
  // Instead, use Binding (@objc dynamic variable)
  @objc dynamic var like: Bool = false

  override var isSelected: Bool {
    didSet {
      self.updateSelection()
    }
  }

  override var highlightState: NSCollectionViewItem.HighlightState {
    didSet {
      self.updateSelection()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    view.wantsLayer = true
    view.layer?.borderWidth = 0.0
    view.layer?.cornerRadius = 8.0
    view.layer?.borderColor = NSColor.selectedControlColor.cgColor
  }

  private func updateSelection() {
    let highlighted =
      self.highlightState == .forSelection || (self.isSelected && self.highlightState != .forDeselection)
      || (self.highlightState == .asDropTarget)
    self.view.layer?.borderWidth = highlighted ? 3.0 : 0.0
  }
}
