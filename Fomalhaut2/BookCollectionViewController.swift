// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxCocoa
import RxRealm
import RxRelay
import RxSwift
import Shared

enum CollectionViewStyle {
  case collection, list
}

enum BookCollectionViewControllerError: Error {
  case openFailure
}

let collectionOrderChangedNotificationName = Notification.Name("collectionOrderChanged")

class BookCollectionViewController: NSSplitViewController, NSMenuItemValidation {
  static let collectionTabViewInitialIndexKey = "collectionTabViewInitialIndex"
  static let collectionOrderKey = "collectionOrder"
  private let tableViewBooks = BehaviorRelay<AnyRealmCollection<Book>?>(value: nil)
  private let collectionViewBooks = BehaviorRelay<AnyRealmCollection<Book>?>(value: nil)
  let collectionViewStyle = BehaviorRelay<CollectionViewStyle>(value: .collection)
  let searchText = BehaviorRelay<String?>(value: nil)
  let tableViewSortDescriptors = BehaviorRelay<[NSSortDescriptor]>(value: [])
  private let collectionOrder = BehaviorRelay<CollectionOrder>(value: .createdAt)
  private let disposeBag = DisposeBag()
  private let bookMenu: NSMenu = NSMenu(title: "Book")
  @IBOutlet weak var tabView: NSTabView!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var collectionView: NSCollectionView!

  private func createLayout(itemSize: NSSize) -> NSCollectionViewLayout {
    let layoutSize = NSCollectionLayoutSize(
      widthDimension: .absolute(itemSize.width), heightDimension: .absolute(itemSize.height))
    let item = NSCollectionLayoutItem(layoutSize: layoutSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemSize.height))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
    let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize, elementKind: NSCollectionView.elementKindSectionHeader, alignment: .top)
    section.boundarySupplementaryItems = [sectionHeader]

    return NSCollectionViewCompositionalLayout(section: section)
  }

  override func viewDidLoad() {
    self.collectionView.menu = self.bookMenu
    self.tableView.menu = self.bookMenu
    self.tableView.registerForDraggedTypes([.fileURL])
    self.collectionView.registerForDraggedTypes([.fileURL])
    self.collectionView.register(
      NSNib(nibNamed: "BookCollectionViewItem", bundle: Bundle.main),
      forItemWithIdentifier: NSUserInterfaceItemIdentifier("BookCollectionViewItem"))
    self.collectionView.register(
      NSNib(nibNamed: "CollectionViewHeaderView", bundle: .main),
      forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader,
      withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CollectionViewHeaderView.className()))
    let initialTabIndex = UserDefaults.standard.integer(
      forKey: BookCollectionViewController.collectionTabViewInitialIndexKey)
    self.collectionViewStyle.accept(initialTabIndex == 0 ? .collection : .list)
    let collectionOrder = CollectionOrder(
      rawValue: UserDefaults.standard.string(forKey: BookCollectionViewController.collectionOrderKey)!)!
    self.collectionOrder.accept(collectionOrder)
    Schema.shared.state
      .skip { $0 != .finish }
      .flatMap { _ in
        Observable.combineLatest(CollectionContent.selected, self.searchText, self.tableViewSortDescriptors)
      }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { (collectionContent, searchText, sortDescriptors) in
        let sorted = sortDescriptors.map {
          SortDescriptor(
            keyPath: $0.key!, ascending: $0.ascending)
        }
        let realm = try! Realm()
        if let collectionContent = collectionContent {
          switch collectionContent {
          case .filter(let filter):
            let predicate: NSPredicate = self.predicateFrom(searchText: searchText, filterPredicate: filter.predicate)
            self.tableViewBooks.accept(
              AnyRealmCollection(realm.objects(Book.self).filter(predicate).sorted(by: sorted)))
          case .collection(let collection):
            self.tableViewBooks.accept(AnyRealmCollection(collection.books.sorted(by: sorted)))
          }
        }
      })
      .disposed(by: self.disposeBag)
    Schema.shared.state
      .skip { $0 != .finish }
      .flatMap { _ in Observable.combineLatest(CollectionContent.selected, self.searchText, self.collectionOrder) }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { (collectionContent, searchText, order) in
        let realm = try! Realm()
        if let collectionContent = collectionContent {
          switch collectionContent {
          case .filter(let filter):
            let predicate: NSPredicate = self.predicateFrom(searchText: searchText, filterPredicate: filter.predicate)
            self.collectionViewBooks.accept(
              AnyRealmCollection(
                realm.objects(Book.self).filter(predicate).sorted(byKeyPath: order.rawValue, ascending: order.ascending)
              ))
          case .collection(let collection):
            self.collectionViewBooks.accept(
              AnyRealmCollection(collection.books.sorted(byKeyPath: order.rawValue, ascending: order.ascending)))
          }
        }
      })
      .disposed(by: self.disposeBag)
    self.collectionViewBooks
      .compactMap { $0 }
      .flatMapLatest { Observable.changeset(from: $0) }
      .map { $0.1 }
      .withUnretained(self)
      .subscribe(onNext: { (owner, changes) in
        if let changes = changes {
          owner.collectionView.applyChangeset(changes)
        } else {
          owner.collectionView.reloadData()
        }
      })
      .disposed(by: self.disposeBag)
    self.tableViewBooks
      .compactMap { $0 }
      .flatMapLatest { Observable.changeset(from: $0) }
      .map { $0.1 }
      .withUnretained(self)
      .subscribe(onNext: { owner, changes in
        if let changes = changes {
          owner.tableView.applyChangeset(changes)
        } else {
          owner.tableView.reloadData()
        }
      })
      .disposed(by: self.disposeBag)
    self.collectionViewStyle
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { collectionViewStyle in
        let tabViewIndex = collectionViewStyle == .collection ? 0 : 1
        self.tabView.selectTabViewItem(at: tabViewIndex)
        UserDefaults.standard.set(tabViewIndex, forKey: BookCollectionViewController.collectionTabViewInitialIndexKey)
      })
      .disposed(by: self.disposeBag)
    CollectionContent.selected
      .compactMap { $0 }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { collectionContent in
        self.updateBookMenu(collectionContent: collectionContent)
        UserDefaults.standard.set(collectionContent.id, forKey: FilterListViewController.selectedCollectionContentIdKey)
      })
      .disposed(by: self.disposeBag)
    self.collectionOrder
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { collectionOrder in
        UserDefaults.standard.set(collectionOrder.rawValue, forKey: BookCollectionViewController.collectionOrderKey)
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
    UserDefaults.standard.rx
      .observe(Int.self, CollectionViewHeaderView.itemSizeIndexKey)
      .withUnretained(self)
      .subscribe(onNext: { owner, itemSizeIndex in
        if let itemSizeIndex = itemSizeIndex {
          owner.collectionView.collectionViewLayout = owner.createLayout(
            itemSize: CollectionViewHeaderView.itemSizes[itemSizeIndex])
        }
      })
      .disposed(by: self.disposeBag)
    super.viewDidLoad()
  }

  override func viewDidAppear() {
    var progressViewController: ProgressViewController? = nil
    Schema.shared.state
      .withUnretained(self)
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { owner, state in
        switch state {
        case .start:
          progressViewController = ProgressViewController(
            nibName: ProgressViewController.className(), bundle: nil)
          owner.presentAsSheet(progressViewController!)
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

  private func resolveBookURL(_ book: Book) -> Single<URL> {
    return Single.create { single in
      var bookmarkDataIsStale: Bool = false
      do {
        let url = try book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale)
        log.debug("bookmarkDataIsStale = \(bookmarkDataIsStale)")
        if bookmarkDataIsStale {
          log.info("Regenerate book.bookmark of \(url.path)")
          do {
            let realm = try Realm()
            try realm.write {
              book.bookmark = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess])
            }
          } catch {
            log.error("error while update bookmark of book \(url.path): \(error)")
            single(.failure(error))
            return Disposables.create()
          }
        }
        single(.success(url))
        return Disposables.create()
      } catch {
        single(.failure(error))
        return Disposables.create()
      }
    }
  }

  func open(_ book: Book) -> Single<Void> {
    return Single.create { single in
      self.resolveBookURL(book).subscribe { url in
        let success = url.startAccessingSecurityScopedResource()
        log.debug("startAccessingSecurityScopedResource = \(success)")
        NSDocumentController.shared.openDocument(withContentsOf: url, display: false) {
          (document, documentWasAlreadyOpen, error) in
          defer {
            url.stopAccessingSecurityScopedResource()
          }
          if let error = error {
            // TODO: show error dialog
            log.error("Error while open a book at \(url.path): \(error)")
            single(.failure(error))
          } else {
            guard let document = document else {
              log.error("Failed to open a document: \(url.path)")
              single(.failure(BookCollectionViewControllerError.openFailure))
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
            }
            single(.success(()))
          }
        }
      } onFailure: { error in
        single(.failure(error))
      }.disposed(by: self.disposeBag)
      return Disposables.create()
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
    guard let item = self.collectionView.item(at: indexPath) as? BookCollectionViewItem else { return }
    item.opening = true
    self.open(self.collectionViewBooks.value![indexPath.item]).subscribe {
      // do nothing
    } onFailure: { error in
      log.error("Error while open a book: \(error)")
      NSAlert(error: error).runModal()
    } onDisposed: {
      item.opening = false
    }.disposed(by: self.disposeBag)
  }

  // Double click the row of TableView
  @IBAction func openBook(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.tableViewBooks.value![index]
      self.open(book).subscribe {
        // do nothing
      } onFailure: { error in
        log.error("Error while open a book: \(error)")
        NSAlert(error: error).runModal()
      }.disposed(by: self.disposeBag)
    }
  }

  func openRandomBook() {
    guard
      let books = self.collectionViewStyle.value == .collection
        ? self.collectionViewBooks.value : self.tableViewBooks.value
    else { return }
    if books.isEmpty {
      return
    }
    let index = Int(arc4random_uniform(UInt32(books.count)))
    self.open(books[index]).subscribe {
      if self.collectionViewStyle.value == .collection {
        let indexPath = IndexPath(item: index, section: 0)
        self.collectionView.deselectAll(nil)
        self.collectionView.selectItems(at: [indexPath], scrollPosition: .top)
      } else {
        self.tableView.deselectAll(nil)
        self.tableView.selectRowIndexes([index], byExtendingSelection: false)
      }
    } onFailure: { error in
      log.error("Error while open a book: \(error)")
      NSAlert(error: error).runModal()
    }.disposed(by: self.disposeBag)
  }

  // MARK: - NSMenu for NSTableView and NSCollectionView
  @objc func openViewer(_ sender: Any) {
    self.selectedBooks().forEach { book in
      var bookCollectionViewItem: BookCollectionViewItem? = nil
      if self.collectionViewStyle.value == .collection {
        if let index = self.collectionViewBooks.value?.index(of: book) {
          bookCollectionViewItem =
            self.collectionView.item(at: IndexPath(item: index, section: 0)) as? BookCollectionViewItem
        }
      }
      bookCollectionViewItem?.opening = true
      self.open(book).subscribe {
        // do nothing
        bookCollectionViewItem?.opening = false
      } onFailure: { error in
        log.error("Error while open a book: \(error)")
        let message = NSLocalizedString("ErrorFileDoesNotExists", comment: "This file does not exists.")
        let information = NSLocalizedString("ErrorBrokenFile", comment: "File is corrupt or unsupported file type")
        self.showModalDialog(message: message, information: information)
      } onDisposed: {
        bookCollectionViewItem?.opening = false
      }.disposed(by: self.disposeBag)
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
        let message = NSLocalizedString("ErrorUnresolvedBookmarkData", comment: "This book might be deleted.")
        self.showModalDialog(message: message, information: "")
      }
    }
  }

  @objc func toggleLike(_ sender: Any) {
    do {
      let realm = try Realm()
      try realm.write {
        self.selectedBooks().forEach { book in
          book.like = !book.like
        }
      }
    } catch {
      // TODO: Show alert
      log.error("Error while like books: \(error)")
    }
  }

  @objc func markUnread(_ sender: Any) {
    do {
      let realm = try Realm()
      try realm.write {
        self.selectedBooks().forEach { book in
          book.readCount = 0
        }
      }
    } catch {
      // TODO: Show alert
      log.error("Error while mark as unread books: \(error)")
    }
  }

  @objc func deleteFromCollection(_ sender: Any) {
    let books = self.selectedBooks()
    if case .collection(let collection) = CollectionContent.selected.value {
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

  func clickedBook() -> Book? {
    if self.collectionViewStyle.value == .list && self.tableView.clickedRow >= 0 {
      return self.tableViewBooks.value![self.tableView.clickedRow]
    } else if !self.collectionView.selectionIndexes.isEmpty {
      return self.collectionViewBooks.value![self.collectionView.selectionIndexes.first!]
    } else {
      return nil
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
    let validExtensionFileURLs = dropFileURLs.flatMap { fileURL -> [URL] in
      if fileURL.hasDirectoryPath {
        do {
          return try FileManager.default.contentsOfDirectory(atPath: fileURL.path)
            .map { URL(fileURLWithPath: $0, relativeTo: fileURL) }
        } catch {
          log.error(error)
        }
        return [fileURL]
      } else {
        return [fileURL]
      }
    }.filter { ["zip", "cbz", "rar", "cbr", "pdf", "7z", "cb7"].contains($0.pathExtension.lowercased()) }
    if validExtensionFileURLs.isEmpty {
      return false
    }
    guard let realm = try? Realm() else {
      log.error("Failed to initialize Realm")
      return true
    }
    validExtensionFileURLs.forEach { (fileURL) in
      if realm.objects(Book.self).filter("filePath = %@", fileURL.path).first != nil {
        log.info("file \(fileURL.path) is already added.")
        return
      }
      let book = Book()
      book.isRightToLeft = Preferences.standard.defaultPageOrder == .rtl
      do {
        try book.setURL(fileURL)
      } catch {
        log.error("Error while create bookmarkData from \(fileURL.path): \(error)")
        return
      }
      // Write before open a NSDocument
      try? realm.write {
        realm.add(book)
        if case .collection(let collection) = CollectionContent.selected.value {
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
        let document: BookDocument
        let pathExtension = url.pathExtension.lowercased()
        if pathExtension == "zip" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: ZipArchiver.utis[0]) as! BookDocument
        } else if pathExtension == "cbz" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: ZipArchiver.utis[1]) as! BookDocument
        } else if pathExtension == "pdf" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: PdfArchiver.utis[0]) as! BookDocument
        } else if pathExtension == "rar" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: RarArchiver.utis[0]) as! BookDocument
        } else if pathExtension == "cbr" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: RarArchiver.utis[1]) as! BookDocument
        } else if pathExtension == "7z" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: SevenZipArchiver.utis[0]) as! BookDocument
        } else if pathExtension == "cb7" {
          document =
            try NSDocumentController.shared.makeDocument(
              withContentsOf: url, ofType: SevenZipArchiver.utis[1]) as! BookDocument
        } else {
          return
        }
        try? realm.write {
          book.pageCount = document.pageCount()
        }
        // Generate thumbnail
        document.image(at: 0).subscribe(onNext: { (result) in
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
      NSMenuItem(
        title: NSLocalizedString("Like", comment: "Like"), action: #selector(toggleLike(_:)), keyEquivalent: "")
    )
    self.bookMenu.addItem(
      NSMenuItem(
        title: NSLocalizedString("MarkUnread", comment: "Mark as unread"), action: #selector(markUnread(_:)),
        keyEquivalent: "")
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
    if selector == #selector(toggleLike(_:)) {
      if let book = self.clickedBook() {
        menuItem.title =
          book.like
          ? NSLocalizedString("CancelLike", comment: "Cancel Like") : NSLocalizedString("Like", comment: "Like")
      }
    }
    if selector == #selector(openViewer(_:)) || selector == #selector(toggleLike(_:))
      || selector == #selector(showFileInFinder(_:))
      || selector == #selector(deleteFromCollection(_:)) || selector == #selector(deleteFromLibrary(_:))
    {
      return !self.selectedBooks().isEmpty
    } else if selector == #selector(markUnread(_:)) {
      guard let book = self.clickedBook() else { return false }
      return book.readCount > 0
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
      cellView.textField?.stringValue = self.tableViewBooks.value![row].displayName
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
        for: indexPath) as! BookCollectionViewItem
    let book = self.collectionViewBooks.value![indexPath.item]
    item.textField?.stringValue = book.displayName
    item.textField?.toolTip = book.displayName
    //item.likeImageView?.isHidden = !book.like
    item.like = book.like
    if let data = book.thumbnailData, let thumbnail = NSImage(data: data) {
      //log.debug("THUMBNAIL SIZE \(thumbnail.representations.first!.pixelsWide) x \(thumbnail.representations.first!.pixelsHigh)")
      item.imageView?.image = thumbnail
      item.imageView?.unregisterDraggedTypes()
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
