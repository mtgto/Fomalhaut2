// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

// Perform as NSCollectionViewGridLayout
class CollectionViewLayout: NSCollectionViewFlowLayout {
  override func prepare() {
    self.itemSize = NSSize(width: 178, height: 272)
    self.headerReferenceSize = NSSize(width: 1000, height: 40)
  }

  override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
    let attrs = super.layoutAttributesForElements(in: rect)
    attrs.forEach { (attr) in
      if attr.representedElementKind == nil {  // Ignore header or footer
        if let indexPath = attr.indexPath,
          let frame = self.layoutAttributesForItem(at: indexPath)?.frame
        {
          attr.frame = frame
        }
      }
    }
    return attrs
  }

  override func layoutAttributesForItem(at indexPath: IndexPath)
    -> NSCollectionViewLayoutAttributes?
  {
    guard let attr = super.layoutAttributesForItem(at: indexPath) else {
      return nil
    }
    if indexPath.item == 0 {
      return attr
    }
    if let prevAttr = self.layoutAttributesForItem(
      at: IndexPath(item: indexPath.item - 1, section: indexPath.section))
    {
      let prevFrame = prevAttr.frame
      if prevFrame.origin.y == attr.frame.origin.y {
        attr.frame = NSRect(
          x: prevFrame.origin.x + prevFrame.size.width + 10, y: prevFrame.origin.y,
          width: prevFrame.size.width, height: prevFrame.size.height)
      }
    }
    return attr
  }
}
