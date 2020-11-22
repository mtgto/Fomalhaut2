// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

// Perform as NSCollectionViewGridLayout
class CollectionViewLayout: NSCollectionViewFlowLayout {
  private let itemWidth: CGFloat = 178
  private let itemHeight: CGFloat = 272
  private let itemSpacing: CGFloat = 10
  private let lineSpacing: CGFloat = 10
  private let headerHeight: CGFloat = 40
  private var numberOfColumns: Int = 1
  private var cellLayoutAttributes: [[NSCollectionViewLayoutAttributes?]] = []
  private var headerLayoutAttributes: [NSCollectionViewLayoutAttributes?] = []
  
  override func prepare() {
    guard let collectionView = self.collectionView else {
      return
    }
    self.numberOfColumns = max(Int((collectionView.frame.width + self.itemSpacing) / (self.itemWidth + self.itemSpacing)), 1)
    self.cellLayoutAttributes = []
    (0..<collectionView.numberOfSections).forEach { section in
      let attributes = (0..<collectionView.numberOfItems(inSection: section)).map { index -> NSCollectionViewLayoutAttributes? in
        let layoutAttribute = self.layoutAttributesForItem(at: IndexPath(item: index, section: section))
        let x = CGFloat(index % numberOfColumns) * (self.itemWidth + self.itemSpacing)
        let y = self.headerHeight + CGFloat(index / numberOfColumns) * (self.itemHeight + self.lineSpacing)
        layoutAttribute?.frame = NSRect(x: x, y: y, width: self.itemWidth, height: self.itemHeight)
        return layoutAttribute
      }
      self.cellLayoutAttributes.append(attributes)
    }
    self.headerLayoutAttributes = (0..<collectionView.numberOfSections).map { section in
      let layoutAttribute = self.layoutAttributesForSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))
      layoutAttribute?.frame.size = NSSize(width: collectionView.frame.width, height: self.headerHeight)
      return layoutAttribute
    }
  }
  
  override var collectionViewContentSize: NSSize {
    guard let collectionView = self.collectionView else { return .zero }
    let width = collectionView.frame.width
    if let lastCellAttribute = self.cellLayoutAttributes.last?.last as? NSCollectionViewLayoutAttributes {
      return NSSize(width: width, height: lastCellAttribute.frame.maxY)
    } else {
      return .zero
    }
  }
  
  override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
    let visibleHeaderLayoutAttributes = self.headerLayoutAttributes.compactMap { $0 }.filter { rect.intersects($0.frame) }
    let visibleCellLayoutAttributes = self.cellLayoutAttributes.map {
      $0.compactMap { $0 }.filter { rect.intersects($0.frame) }
    }
    .reduce([], +)
    return visibleHeaderLayoutAttributes + visibleCellLayoutAttributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
    if self.cellLayoutAttributes.count > indexPath.section && self.cellLayoutAttributes[indexPath.section].count > indexPath.item {
      return self.cellLayoutAttributes[indexPath.section][indexPath.item]
    }
    return NSCollectionViewLayoutAttributes(forItemWith: indexPath)
  }
  
  override func layoutAttributesForSupplementaryView(ofKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
    // Ignore section of indexPath (each header has same size)
    guard elementKind == NSCollectionView.elementKindSectionHeader else {
      return nil
    }
    if self.headerLayoutAttributes.count > indexPath.section {
      return self.headerLayoutAttributes[indexPath.section]
    }
    let layoutAttribute = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
    return layoutAttribute
  }
  
  override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
//    let newNumberOfColumns = max(Int((newBounds.width + self.itemSpacing) / (self.itemWidth + self.itemSpacing)), 1)
//    return self.numberOfColumns != newNumberOfColumns

    // Resize header frame to fix header position in right
    return true
  }
}
