// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRealm
import RxRelay
import RxSwift

class FilterListViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
  private let rootItems = [
    NSLocalizedString("LibraryHeader", comment: "Library"),
    NSLocalizedString("CollectionHeader", comment: "Collection"),
  ]
  // TODO: Use PublishSubject to add/remove filter by user
  private let filters: [Filter] = [
    Filter(name: NSLocalizedString("AllFilter", comment: "All"), predicate: NSPredicate(format: "readCount >= 0")),
    Filter(name: NSLocalizedString("UnreadFilter", comment: "Unread"), predicate: NSPredicate(format: "readCount = 0")),
    Filter(name: NSLocalizedString("LikeFilter", comment: "Like"), predicate: NSPredicate(format: "%K = true", "like")),
  ]
  private let collections = BehaviorRelay<Results<Collection>?>(value: nil)
  private var selectedCollectionContent = BehaviorRelay<CollectionContent?>(value: nil)
  private let disposeBag = DisposeBag()
  @IBOutlet weak var filterListView: NSOutlineView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Accept from Collection View or List View
    self.filterListView.registerForDraggedTypes([.fileURL])
    Schema.shared.state
      .skip { $0 != .finish }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { _ in
        let realm = try! Realm()
        self.collections.accept(realm.objects(Collection.self).sorted(byKeyPath: "createdAt"))
      })
      .disposed(by: self.disposeBag)
    // TODO: MUST remove items from NSOutlineView before delete from Realm.
    // https://github.com/realm/realm-cocoa/issues/6169
    NotificationCenter.default.rx.notification(collectionWillDeleteNotificationName, object: nil)
      .subscribe(onNext: { notification in
        if let collection = notification.userInfo?["collection"] as? Collection {
          if let index = self.collections.value?.index(of: collection) {
            self.filterListView.removeItems(at: IndexSet([index]), inParent: self.rootItems[1])
          }
        }
      })
      .disposed(by: self.disposeBag)
    self.collections
      .compactMap { $0 }
      .flatMapLatest { Observable.changeset(from: $0) }
      .map { $0.1 }
      .withUnretained(self)
      .subscribe(onNext: { owner, changes in
        let lastSelectedRow = owner.filterListView.selectedRow
        let lastSelectedItem = owner.filterListView.item(atRow: lastSelectedRow) ?? self.filters[0]
        self.filterListView.reloadItem(owner.rootItems[1], reloadChildren: true)
        // If user delete selected row, selection is initialized (all books)
        let row = owner.filterListView.row(forItem: lastSelectedItem)
        owner.filterListView.selectRowIndexes(IndexSet([row < 0 ? 1 : row]), byExtendingSelection: false)
      })
      .disposed(by: self.disposeBag)
    self.rootItems.forEach { (rootItem) in
      self.filterListView.expandItem(rootItem)
    }
    self.selectedCollectionContent
      .distinctUntilChanged()
      .compactMap { $0 }
      .subscribe(onNext: { collectionContent in
        switch collectionContent {
        case .filter(let filter):
          NotificationCenter.default.post(
            name: filterChangedNotificationName, object: nil, userInfo: ["filter": filter])
        case .collection(let collection):
          NotificationCenter.default.post(
            name: collectionChangedNotificationName, object: nil, userInfo: ["collection": collection])
        }
      })
      .disposed(by: self.disposeBag)
  }

  func addNewCollection() {
    let collection = Collection()
    collection.name = "New Collection"
    do {
      let realm = try Realm()
      try realm.write {
        realm.add(collection)
      }
    } catch {
      log.error("Error while adding new collection: \(error)")
    }
  }

  // MARK: - NSOutlineViewDataSource
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      return self.rootItems[index]
    } else if let rootItem = item as? String {
      if rootItem == self.rootItems[0] {
        return self.filters[index]
      } else if rootItem == self.rootItems[1] {
        return self.collections.value![index]
      }
    }
    // Not Implemented
    return "Not Implemented"
  }

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if item is Filter || item is Collection {
      return false
    }
    return true
  }

  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return self.rootItems.count
    } else if let rootItem = item as? String {
      if rootItem == self.rootItems[0] {
        return self.filters.count
      } else if rootItem == self.rootItems[1] {
        return self.collections.value?.count ?? 0
      } else {
        log.error("Unexpected item for numberOfChildrenOfItem. item: \(item ?? "nil")")
        return 0
      }
    } else {
      return 0
    }
  }

  func outlineView(
    _ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?
  ) -> Any? {
    return item
  }

  func outlineView(
    _ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?,
    proposedChildIndex index: Int
  ) -> NSDragOperation {
    if let collection = item as? Collection {
      if info.draggingSource is NSCollectionView || info.draggingSource is NSTableView {
        let dropFiles = info.draggingPasteboard.readObjects(
          forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: 1])
        return .copy
      }
    }
    return []
  }

  func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int)
    -> Bool
  {
    guard let realm = try? Realm() else {
      // TODO: Show alert
      log.error("Failed to initialize Realm")
      return false
    }
    if let collection = item as? Collection {
      guard
        let dropFileURLs = info.draggingPasteboard.readObjects(
          forClasses: [NSURL.self],
          options: [
            .urlReadingFileURLsOnly: 1
          ])
          as? [URL]
      else {
        return false
      }

      let fileURLs = dropFileURLs.filter { fileURL in
        !collection.books.contains(where: { $0.filePath == fileURL.path })
      }
      let books = realm.objects(Book.self).filter("filePath IN %@", fileURLs.map { $0.path })
      try? realm.write {
        collection.books.append(objectsIn: books)
      }
      return true
    }

    return false
  }

  // MARK: NSOutlineViewDelegate
  func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
    return true
  }

  func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
    if item is String {
      return false
    }
    return true
  }

  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
    return item is Collection
  }

  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any)
    -> NSView?
  {
    if let label = item as? String {
      let cell =
        outlineView.makeView(
          withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: outlineView)
        as! NSTableCellView
      cell.textField?.stringValue = label
      return cell
    } else {
      let cell =
        outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: outlineView)
        as! NSTableCellView
      if let filter = item as? Filter {
        cell.textField?.stringValue = filter.name
        cell.textField?.isEditable = false
      } else if let collection = item as? Collection {
        cell.textField?.stringValue = collection.name
        cell.textField?.isEditable = true
      } else {
        log.error("Unexpected tableColumn. item: \(item)")
        return nil
      }
      return cell
    }
  }

  func outlineViewSelectionDidChange(_ notification: Notification) {
    //log.info("selectedRow = \(self.filterListView.selectedRow)")
    let item = self.filterListView.item(atRow: self.filterListView.selectedRow)
    if let filter = item as? Filter {
      self.selectedCollectionContent.accept(.filter(filter))
    } else if let collection = item as? Collection {
      self.selectedCollectionContent.accept(.collection(collection))
    }
  }
}

// MARK: NSControlTextEditingDelegate
extension FilterListViewController: NSControlTextEditingDelegate {
  func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
    // Collection name should not be empty
    return !fieldEditor.string.isEmpty
  }

  func controlTextDidEndEditing(_ obj: Notification) {
    log.debug("controlTextDidEndEditing. \(self.filterListView.clickedRow) \(self.filterListView.selectedRow)")
    if let textField = obj.object as? NSTextField,
      let collection = self.filterListView.item(atRow: self.filterListView.selectedRow) as? Collection
    {
      do {
        try Realm().write {
          collection.name = textField.stringValue
        }
      } catch {
        // TODO: Show alert
        log.error("Error while updating collection name to \(textField.stringValue)")
      }
    }
  }
}
