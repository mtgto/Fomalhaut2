// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxCocoa
import RxRealm
import RxRelay
import RxSwift

enum CollectionViewStyle {
  case collection, list
}

enum CollectionOrder: String {
  case createdAt = "createdAt"
  case readCount = "readCount"
}

class BookCollectionViewController: NSSplitViewController, NSMenuItemValidation {
  private let tableViewBooks = BehaviorRelay<AnyRealmCollection<Book>?>(value: nil)
  private let collectionViewBooks = BehaviorRelay<AnyRealmCollection<Book>?>(value: nil)
  let collectionViewStyle = BehaviorRelay<CollectionViewStyle>(value: .collection)
  let searchText = BehaviorRelay<String?>(value: nil)
  let collectionContent = BehaviorRelay<CollectionContent?>(value: nil)
  let tableViewSortDescriptors = BehaviorRelay<[NSSortDescriptor]>(value: [])
  private let collectionOrder = BehaviorRelay<CollectionOrder>(value: .createdAt)
  private let disposeBag = DisposeBag()
  private let bookMenu: NSMenu = NSMenu(title: "Book")
  @IBOutlet weak var tabView: NSTabView!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var collectionView: NSCollectionView!

  override func viewDidLoad() {
    // Do view setup here.
    self.collectionView.menu = self.bookMenu
    self.tableView.menu = self.bookMenu
    self.tableView.registerForDraggedTypes([.fileURL])
    self.collectionView.registerForDraggedTypes([.fileURL])
    self.collectionView.register(
      NSNib(nibNamed: "CollectionViewHeaderView", bundle: .main),
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CollectionViewHeaderView.className()))
    Schema.shared.state
      .skipWhile { $0 != .finish }
      .flatMap { _ in
        Observable.combineLatest(self.collectionContent, self.searchText, self.tableViewSortDescriptors)
      }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (collectionContent, searchText, sortDescriptors) in
        let sorted = sortDescriptors.map {
          SortDescriptor(
            keyPath: $0.key!, ascending: $0.ascending)
        }
        let realm = try! Realm()
        if let collectionContent = collectionContent {
          switch collectionContent {
          case .filter(let filter):
            let filterPredicate: NSPredicate = NSPredicate(format: filter.predicate)
            let predicate: NSPredicate = self.predicateFrom(searchText: searchText, filterPredicate: filterPredicate)
            self.tableViewBooks.accept(
              AnyRealmCollection(realm.objects(Book.self).filter(predicate).sorted(by: sorted)))
          case .collection(let collection):
            self.tableViewBooks.accept(AnyRealmCollection(collection.books.sorted(by: sorted)))
          }
        }
      })
      .disposed(by: self.disposeBag)
    Schema.shared.state
      .skipWhile { $0 != .finish }
      .flatMap { _ in Observable.combineLatest(self.collectionContent, self.searchText, self.collectionOrder) }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (collectionContent, searchText, order) in
        let realm = try! Realm()
        if let collectionContent = collectionContent {
          switch collectionContent {
          case .filter(let filter):
            let filterPredicate: NSPredicate = NSPredicate(format: filter.predicate)
            let predicate: NSPredicate = self.predicateFrom(searchText: searchText, filterPredicate: filterPredicate)
            self.collectionViewBooks.accept(
              AnyRealmCollection(
                realm.objects(Book.self).filter(predicate).sorted(byKeyPath: order.rawValue, ascending: false)))
          case .collection(let collection):
            self.collectionViewBooks.accept(
              AnyRealmCollection(collection.books.sorted(byKeyPath: order.rawValue, ascending: false)))
          }
        }
      })
      .disposed(by: self.disposeBag)
    self.collectionViewBooks
      .compactMap { $0 }
      .flatMapLatest { Observable.changeset(from: $0) }
      .subscribe(onNext: { [unowned self] _, changes in
        if let changes = changes {
          self.collectionView.applyChangeset(changes)
        } else {
          self.collectionView.reloadData()
        }
      })
      .disposed(by: self.disposeBag)
    self.tableViewBooks
      .compactMap { $0 }
      .flatMapLatest { Observable.changeset(from: $0) }
      .subscribe(onNext: { [unowned self] _, changes in
        if let changes = changes {
          self.tableView.applyChangeset(changes)
        } else {
          self.tableView.reloadData()
        }
      })
      .disposed(by: self.disposeBag)
    self.collectionViewStyle
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { collectionViewStyle in
        self.tabView.selectTabViewItem(at: collectionViewStyle == .collection ? 0 : 1)
      })
      .disposed(by: self.disposeBag)
    self.collectionContent
      .compactMap { $0 }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { collectionContent in
        self.updateBookMenu(collectionContent: collectionContent)
      })
      .disposed(by: self.disposeBag)
    NotificationCenter.default.rx.notification(filterChangedNotificationName, object: nil)
      .subscribe(onNext: { notification in
        if let filter = notification.userInfo?["filter"] as? Filter {
          log.debug("Filter selected: \(filter.name), \(filter.predicate)")
          self.collectionContent.accept(.filter(filter))
        } else {
          log.error("Unsupported userInfo from filterChangedNotification")
        }
      })
      .disposed(by: self.disposeBag)
    NotificationCenter.default.rx.notification(collectionChangedNotificationName, object: nil)
      .subscribe(onNext: { notification in
        if let collection = notification.userInfo?["collection"] as? Collection {
          log.debug("Collection selected: \(collection.name)")
          self.collectionContent.accept(.collection(collection))
        } else {
          log.error("Unsupported userInfo from collectionChangedNotification")
        }
      })
      .disposed(by: self.disposeBag)
    NotificationCenter.default.rx.notification(collectionOrderChangedNotificationName, object: nil)
      .subscribe(onNext: { notification in
        if let order = notification.userInfo?["order"] as? CollectionOrder {
          log.info("Collection order selected: \(order)")
          self.collectionOrder.accept(order)
        } else {
          log.error("Unsupported userInfo from collectionOrderChangedNotification")
        }
      })
      .disposed(by: self.disposeBag)
    super.viewDidLoad()
  }

  override func viewDidAppear() {
    var progressViewController: ProgressViewController? = nil
    Schema.shared.state
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [unowned self] state in
        switch state {
        case .start:
          progressViewController = ProgressViewController(
            nibName: ProgressViewController.className(), bundle: nil)
          self.presentAsSheet(progressViewController!)
        case .finish:
          if let progressViewController = progressViewController {
            self.dismiss(progressViewController)
          }
        }
      })
      .disposed(by: self.disposeBag)
  }

  func predicateFrom(searchText: String?, filterPredicate: NSPredicate?) -> NSPredicate {
    let searchPredicate: NSPredicate?
    if let searchText = searchText, !searchText.isEmpty {
      searchPredicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
    } else {
      searchPredicate = nil
    }
    return NSCompoundPredicate(
      andPredicateWithSubpredicates: [filterPredicate, searchPredicate].compactMap { $0 })
  }

  func open(_ book: Book) {
    var bookmarkDataIsStale: Bool = false
    do {
      let url = try book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale)
      log.debug("bookmarkDataIsStale = \(bookmarkDataIsStale)")
      if bookmarkDataIsStale {
        log.info("Regenerate book.bookmark of \(url.path)")
        do {
          let realm = try Realm()
          try realm.write {
            book.bookmark = try url.bookmarkData(options: [
              .withSecurityScope, .securityScopeAllowOnlyReadAccess,
            ])
          }
        } catch {
          log.error("error while update bookmark of book \(url.path): \(error)")
        }
      }
      do {
        let realm = try Realm()
        try realm.write {
          book.readCount = book.readCount + 1
        }
      }
      let success = url.startAccessingSecurityScopedResource()
      log.debug("success = \(success)")
      // TODO: Call url.stopAccessingSecurityScopedResource() after document is closed
      NSDocumentController.shared.openDocument(withContentsOf: url, display: false) {
        (document, documentWasAlreadyOpen, error) in
        if let error = error {
          // TODO: show error dialog
          log.error("Error while open a book at \(url.path): \(error)")
          NSAlert(error: error).runModal()
        } else {
          guard let document = document else {
            log.error("Failed to open a document: \(url.path)")
            return
          }
          if documentWasAlreadyOpen {
            document.showWindows()
          } else {
            if let document = document as? BookDocument {
              document.book = book.freeze()
            }
            document.makeWindowControllers()
            document.showWindows()
            //url.stopAccessingSecurityScopedResource()
          }
        }
      }
    } catch {
      // TODO: show error dialog
      log.error("Error while resolve URL from a book: \(error)")
    }
  }

  func showModalDialog(message: String, information: String) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = message
    alert.informativeText = information
    alert.runModal()
  }

  func setCollectionViewStyle(_ collectionViewStyle: CollectionViewStyle) {
    self.collectionViewStyle.accept(collectionViewStyle)
  }

  // called when the item of NSCollectionView is double-clicked
  func openCollectionViewBook(_ indexPath: IndexPath) {
    self.open(self.collectionViewBooks.value![indexPath.item])
  }

  // Double click the row of TableView
  @IBAction func openBook(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.tableViewBooks.value![index]
      self.open(book)
    }
  }

  // MARK: - NSMenu for NSTableView and NSCollectionView
  @objc func openViewer(_ sender: Any) {
    self.selectedBooks().forEach { book in
      self.open(book)
    }
  }

  @objc func showFileInFinder(_ sender: Any) {
    // TODO: what selection is best...?
    if let book = self.selectedBooks().first {
      var bookmarkDataIsStale = false
      if let url = try? book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale) {
        _ = url.startAccessingSecurityScopedResource()
        NSWorkspace.shared.activateFileViewerSelecting([url])
        url.stopAccessingSecurityScopedResource()
      } else {
        // TODO: show error dialog
        self.showModalDialog(message: "", information: "")
      }
    }
  }

  @objc func like(_ sender: Any) {
    do {
      let realm = try Realm()
      try realm.write {
        self.selectedBooks().forEach { book in
          book.like = true
        }
      }
    } catch {
      log.error("Error while like books: \(error)")
    }
  }

  @objc func dislike(_ sender: Any) {
    do {
      let realm = try Realm()
      try realm.write {
        self.selectedBooks().forEach { book in
          book.like = false
        }
      }
    } catch {
      log.error("Error while dislike books: \(error)")
    }
  }

  @objc func deleteFromCollection(_ sender: Any) {
    let books = self.selectedBooks()
    if case .collection(let collection) = self.collectionContent.value {
      let indexes = books.compactMap { collection.books.index(of: $0) }
      do {
        let realm = try Realm()
        try realm.write {
          collection.books.remove(atOffsets: IndexSet(indexes))
        }
      } catch {
        // TODO: Show alert
        log.error("Error while deleting a book from collection \(collection.name)")
      }
    }
  }

  @objc func deleteFromLibrary(_ sender: Any) {
    let books = self.selectedBooks()
    Observable.from(books)
      .subscribe(Realm.rx.delete())
      .disposed(by: self.disposeBag)
  }

  func selectedBooks() -> [Book] {
    if self.collectionViewStyle.value == .collection {
      return self.collectionView.selectionIndexPaths.map {
        self.collectionViewBooks.value![$0.item]
      }
    } else {
      return self.tableView.selectedRowIndexes.map {
        self.tableViewBooks.value![$0]
      }
    }
  }

  // Verify dragged files are suitable for
  func validateDraggingInfo(_ info: NSDraggingInfo) -> Bool {
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
    guard let realm = try? Realm() else {
      log.error("Failed to initialize Realm")
      return true
    }
    dropFileURLs.forEach { (fileURL) in
      let book = Book()
      do {
        try book.setURL(fileURL)
      } catch {
        log.error("Error while create bookmarkData from \(fileURL.path): \(error)")
        return
      }
      // Write before open a NSDocument
      try? realm.write {
        realm.add(book)
        if case .collection(let collection) = self.collectionContent.value {
          collection.books.append(book)
        }
      }
      // TODO: Validate whether file contains one or more images? for example get thumbnail
      var bookmarkDataIsStale = false
      guard let url = try? book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale) else {
        log.warning("Unresolved file is dropped")
        return
      }
      _ = url.startAccessingSecurityScopedResource()
      do {
        let document: BookAccessible
        if url.pathExtension.lowercased() == "zip" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: ZipDocument.utis[0]) as! ZipDocument
        } else if url.pathExtension.lowercased() == "cbz" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: ZipDocument.utis[1]) as! ZipDocument
        } else if url.pathExtension.lowercased() == "pdf" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: PdfDocument.utis[0]) as! PdfDocument
        } else if url.pathExtension.lowercased() == "rar" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: RarDocument.utis[0]) as! RarDocument
        } else if url.pathExtension.lowercased() == "cbr" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: RarDocument.utis[1]) as! RarDocument
        } else {
          return
        }
        try? realm.write {
          book.pageCount = document.pageCount()
        }
        // Generate thumbnail
        Observable<Result<NSImage, Error>>.create { observer in
          document.image(at: 0) { (result) in
            observer.onNext(result)
            observer.onCompleted()
          }
          return Disposables.create()
        }.subscribe(onNext: { (result) in
          url.stopAccessingSecurityScopedResource()
          document.close()
        }).disposed(by: self.disposeBag)
      } catch {
        log.error("Failed to open a document: \(error)")
      }
    }

    return true
  }

  func updateBookMenu(collectionContent: CollectionContent) {
    self.bookMenu.removeAllItems()
    self.bookMenu.addItem(
      NSMenuItem(
        title: NSLocalizedString("CollectionBookMenuOpen", comment: "Open"), action: #selector(openViewer(_:)),
        keyEquivalent: ""))
    self.bookMenu.addItem(
      NSMenuItem(title: NSLocalizedString("Like", comment: "Like"), action: #selector(like(_:)), keyEquivalent: "")
    )
    self.bookMenu.addItem(
      NSMenuItem(
        title: NSLocalizedString("CollectionBookMenuShowInFinder", comment: "Show in Finder"),
        action: #selector(showFileInFinder(_:)), keyEquivalent: ""))
    self.bookMenu.addItem(NSMenuItem.separator())
    if case .collection(_) = collectionContent {
      self.bookMenu.addItem(
        NSMenuItem(
          title: NSLocalizedString("CollectionBookMenuDeleteFromCollection", comment: "Delete from collection"),
          action: #selector(deleteFromCollection(_:)), keyEquivalent: ""))
    } else {
      self.bookMenu.addItem(
        NSMenuItem(
          title: NSLocalizedString("CollectionBookMenuDeleteFromLibrary", comment: "Delete from library"),
          action: #selector(deleteFromLibrary(_:)), keyEquivalent: ""))
    }
  }

  // MARK: NSMenuItemValidation
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(openViewer(_:)) || selector == #selector(like(_:))
      || selector == #selector(showFileInFinder(_:))
      || selector == #selector(deleteFromCollection(_:)) || selector == #selector(deleteFromLibrary(_:))
    {
      if self.collectionViewStyle.value == .list {
        return self.tableView.clickedRow >= 0
      } else {
        return !self.collectionView.selectionIndexes.isEmpty
      }
    }
    return false
  }
}

// MARK: - NSTableViewDataSource
extension BookCollectionViewController: NSTableViewDataSource {
  func numberOfRows(in: NSTableView) -> Int {
    return self.tableViewBooks.value?.count ?? 0
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int)
    -> Any?
  {
    let book = self.tableViewBooks.value![row]
    if let columnIdentifier = tableColumn?.identifier {
      switch columnIdentifier {
      case NSUserInterfaceItemIdentifier("name"):
        return book.name
      case NSUserInterfaceItemIdentifier("view"):
        return book.readCount
      default:
        return nil
      }
    }
    log.error("Unset table column identifier!")
    return nil
  }

  func tableView(
    _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
    proposedDropOperation dropOperation: NSTableView.DropOperation
  ) -> NSDragOperation {
    // Limitation: You can not reorder books for now
    if let source = info.draggingSource as? NSTableView, source == tableView {
      return []
    }
    let dropFileCount =
      info.draggingPasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [
          .urlReadingFileURLsOnly: 1
        ])?
      .count ?? 0
    if dropFileCount == 0 {
      return []
    }

    tableView.setDropRow(-1, dropOperation: .on)
    return .copy
  }

  func tableView(
    _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
    dropOperation: NSTableView.DropOperation
  ) -> Bool {
    return self.validateDraggingInfo(info)
  }

  func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
    let book = self.tableViewBooks.value![row]
    var isStale = false
    return try? book.resolveURL(bookmarkDataIsStale: &isStale) as NSURL
  }
}

// MARK: NSTableViewDelegate
extension BookCollectionViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let identifier = tableColumn?.identifier,
      let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
    else {
      return nil
    }
    switch identifier.rawValue {
    case "name":
      cellView.textField?.stringValue = self.tableViewBooks.value![row].name
    case "view":
      cellView.textField?.stringValue = String(self.tableViewBooks.value![row].readCount)
    case "like":
      cellView.textField?.stringValue = self.tableViewBooks.value![row].like ? "♥" : ""
    default:
      break
    }

    return cellView
  }

  func tableView(
    _ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]
  ) {
    log.debug("sortDescriptorsDidChange: \(tableView.sortDescriptors)")
    self.tableViewSortDescriptors.accept(tableView.sortDescriptors)
  }
}

// MARK: - NSCollectionViewDataSource
extension BookCollectionViewController: NSCollectionViewDataSource {
  func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int)
    -> Int
  {
    return self.collectionViewBooks.value?.count ?? 0
  }

  func collectionView(
    _ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath
  ) -> NSCollectionViewItem {
    let item: BookCollectionViewItem =
      collectionView.makeItem(
        withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "BookCollectionViewItem"),
        for: indexPath) as? BookCollectionViewItem ?? BookCollectionViewItem()
    let book = self.collectionViewBooks.value![indexPath.item]
    item.textField?.stringValue = book.name
    item.textField?.toolTip = book.name
    item.likeImageView?.isHidden = !book.like
    if let data = book.thumbnailData, let thumbnail = NSImage(data: data) {
      //log.debug("THUMBNAIL SIZE \(thumbnail.representations.first!.pixelsWide) x \(thumbnail.representations.first!.pixelsHigh)")
      item.imageView?.image = thumbnail
    } else {
      // TODO: Use more user friendly image
      item.imageView?.image = NSImage(named: NSImage.bookmarksTemplateName)
    }
    return item
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
    at indexPath: IndexPath
  ) -> NSView {
    if kind == NSCollectionView.elementKindSectionHeader {
      let view = collectionView.makeSupplementaryView(
        ofKind: kind,
        withIdentifier: NSUserInterfaceItemIdentifier(
          rawValue: CollectionViewHeaderView.className()),
        for: indexPath)
      return view
    } else {
      return NSView()
    }
  }
}

// MARK: NSCollectionViewDelegate
extension BookCollectionViewController: NSCollectionViewDelegate {
  func collectionView(
    _ collectionView: NSCollectionView,
    validateDrop draggingInfo: NSDraggingInfo,
    proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
    dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
  ) -> NSDragOperation {
    // Limitation: You can not reorder books for now
    if let source = draggingInfo.draggingSource as? NSCollectionView, source == collectionView {
      return []
    }
    let dropFileCount =
      draggingInfo.draggingPasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [
          .urlReadingFileURLsOnly: 1
        ])?
      .count ?? 0
    if dropFileCount == 0 {
      return []
    }
    return .copy
  }

  func collectionView(
    _ collectionView: NSCollectionView,
    acceptDrop draggingInfo: NSDraggingInfo,
    indexPath: IndexPath,
    dropOperation: NSCollectionView.DropOperation
  ) -> Bool {
    return self.validateDraggingInfo(draggingInfo)
  }

  func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath)
    -> NSPasteboardWriting?
  {
    let book = self.collectionViewBooks.value![indexPath.item]
    var isStale = false
    return try? book.resolveURL(bookmarkDataIsStale: &isStale) as NSURL
  }

  // Hack to remain collection view cell during dragging: https://stackoverflow.com/a/59893170/6945346
  func collectionView(
    _ collectionView: NSCollectionView,
    draggingSession session: NSDraggingSession,
    willBeginAt screenPoint: NSPoint,
    forItemsAt indexPaths: Set<IndexPath>
  ) {
    indexPaths.forEach { collectionView.item(at: $0)?.view.isHidden = false }
  }
}
