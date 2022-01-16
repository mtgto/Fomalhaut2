// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxRelay
import RxSwift

// Perform as NSCollectionViewGridLayout
class CollectionViewLayout: NSCollectionViewFlowLayout {
  static let itemSizeIndexKey = "collectionViewitemSizeIndex"
  static let itemSizeIndex = BehaviorRelay<Int>(value: 1)
  private static let itemSizes: [NSSize] = [
    NSMakeSize(100.125, 153), NSMakeSize(120.15, 183.6), NSMakeSize(133.5, 204),
  ]
  private let disposeBag = DisposeBag()
  private let itemSpacing: CGFloat = 10
  private let lineSpacing: CGFloat = 10
  private let headerHeight: CGFloat = 40
  private let leftMargin: CGFloat = 8
  private var numberOfColumns: Int = 1
  private var cellLayoutAttributes: [[NSCollectionViewLayoutAttributes?]] = []
  private var headerLayoutAttributes: [NSCollectionViewLayoutAttributes?] = []

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    CollectionViewLayout.itemSizeIndex.accept(
      UserDefaults.standard.integer(forKey: CollectionViewLayout.itemSizeIndexKey))
    CollectionViewLayout.itemSizeIndex
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { itemSizeIndex in
        self.invalidateLayout()
        UserDefaults.standard.set(itemSizeIndex, forKey: CollectionViewLayout.itemSizeIndexKey)
      })
      .disposed(by: self.disposeBag)
  }

  override func prepare() {
    guard let collectionView = self.collectionView else {
      return
    }
    let itemSize = CollectionViewLayout.itemSizes[CollectionViewLayout.itemSizeIndex.value]
    let itemWidth = itemSize.width
    let itemHeight = itemSize.height
    self.numberOfColumns = max(
      Int((collectionView.frame.width + self.itemSpacing - self.leftMargin) / (itemWidth + self.itemSpacing)), 1)
    self.cellLayoutAttributes = []
    (0..<collectionView.numberOfSections).forEach { section in
      let attributes = (0..<collectionView.numberOfItems(inSection: section)).map {
        index -> NSCollectionViewLayoutAttributes? in
        let layoutAttribute = self.layoutAttributesForItem(
          at: IndexPath(item: index, section: section))
        let x = CGFloat(index % numberOfColumns) * (itemWidth + self.itemSpacing) + self.leftMargin
        let y = self.headerHeight + CGFloat(index / numberOfColumns) * (itemHeight + self.lineSpacing)
        layoutAttribute?.frame = NSRect(x: x, y: y, width: itemWidth, height: itemHeight)
        return layoutAttribute
      }
      self.cellLayoutAttributes.append(attributes)
    }
    self.headerLayoutAttributes = (0..<collectionView.numberOfSections).map { section in
      let layoutAttribute = self.layoutAttributesForSupplementaryView(
        ofKind: NSCollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section))
      layoutAttribute?.frame.size = NSSize(
        width: collectionView.frame.width, height: self.headerHeight)
      return layoutAttribute
    }
  }

  override var collectionViewContentSize: NSSize {
    guard let collectionView = self.collectionView else {
      return .zero
    }
    let width = collectionView.frame.width
    if let last = self.cellLayoutAttributes.last?.last, let lastCellAttribute = last {
      return NSSize(width: width, height: lastCellAttribute.frame.maxY)
    } else {
      return .zero
    }
  }

  override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
    let visibleHeaderLayoutAttributes = self.headerLayoutAttributes.compactMap { $0 }.filter {
      rect.intersects($0.frame)
    }
    let visibleCellLayoutAttributes = self.cellLayoutAttributes.map {
      $0.compactMap { $0 }.filter { rect.intersects($0.frame) }
    }
    .reduce([], +)
    return visibleHeaderLayoutAttributes + visibleCellLayoutAttributes
  }

  override func layoutAttributesForItem(at indexPath: IndexPath)
    -> NSCollectionViewLayoutAttributes?
  {
    if self.cellLayoutAttributes.count > indexPath.section
      && self.cellLayoutAttributes[indexPath.section].count > indexPath.item
    {
      return self.cellLayoutAttributes[indexPath.section][indexPath.item]
    }
    return NSCollectionViewLayoutAttributes(forItemWith: indexPath)
  }

  override func layoutAttributesForSupplementaryView(
    ofKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath
  ) -> NSCollectionViewLayoutAttributes? {
    // Ignore section of indexPath (each header has same size)
    guard elementKind == NSCollectionView.elementKindSectionHeader else {
      return nil
    }
    if self.headerLayoutAttributes.count > indexPath.section {
      return self.headerLayoutAttributes[indexPath.section]
    }
    let layoutAttribute = NSCollectionViewLayoutAttributes(
      forSupplementaryViewOfKind: elementKind, with: indexPath)
    return layoutAttribute
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
    let itemSize = CollectionViewLayout.itemSizes[CollectionViewLayout.itemSizeIndex.value]
    let newNumberOfColumns = max(
      Int((newBounds.width + self.itemSpacing - self.leftMargin) / (itemSize.width + self.itemSpacing)), 1)
    //    return self.numberOfColumns != newNumberOfColumns
    if self.numberOfColumns != newNumberOfColumns {
      self.collectionView?.animator().performBatchUpdates(nil)
    }
    // Resize header frame to fix header position in right
    return true
  }
}
