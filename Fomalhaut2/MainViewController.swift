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

class MainViewController: NSSplitViewController, NSMenuItemValidation {
  private let tableViewBooks = BehaviorRelay<Results<Book>?>(value: nil)
  private let collectionViewBooks = BehaviorRelay<Results<Book>?>(value: nil)
  let collectionViewStyle = BehaviorRelay<CollectionViewStyle>(value: .collection)
  let searchText = BehaviorRelay<String?>(value: nil)
  let filter = BehaviorRelay<Filter?>(value: nil)
  let tableViewSortDescriptors = BehaviorRelay<[NSSortDescriptor]>(value: [])
  private let disposeBag = DisposeBag()
  @IBOutlet weak var tabView: NSTabView!
  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var collectionView: NSCollectionView!
  @IBOutlet weak var collectionViewGridLayout: NSCollectionViewGridLayout!

  override func viewDidLoad() {
    // Do view setup here.
    self.tableView.registerForDraggedTypes([.fileURL])
    self.collectionView.registerForDraggedTypes([.fileURL])
    self.collectionViewGridLayout.minimumInteritemSpacing = 5.0
    self.collectionViewGridLayout.minimumLineSpacing = 3.0
    Schema.shared.state
      .skipWhile { $0 != .finish }
      .flatMap { _ in
        Observable.combineLatest(self.filter, self.searchText, self.tableViewSortDescriptors)
      }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (filter, searchText, sortDescriptors) in
        let realm = try! Realm()
        let filterPredicate: NSPredicate?
        if let filter = filter {
          filterPredicate = NSPredicate(format: filter.predicate)
        } else {
          filterPredicate = nil
        }
        let predicate: NSPredicate = self.predicateFrom(
          searchText: searchText, filterPredicate: filterPredicate)
        let sorted = sortDescriptors.map {
          SortDescriptor(
            keyPath: $0.key!, ascending: $0.ascending)
        }
        self.tableViewBooks.accept(realm.objects(Book.self).filter(predicate).sorted(by: sorted))
      })
      .disposed(by: self.disposeBag)
    Schema.shared.state
      .skipWhile { $0 != .finish }
      .flatMap { _ in Observable.combineLatest(self.filter, self.searchText) }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (filter, searchText) in
        let realm = try! Realm()
        let filterPredicate: NSPredicate?
        if let filter = filter {
          filterPredicate = NSPredicate(format: filter.predicate)
        } else {
          filterPredicate = nil
        }
        let predicate: NSPredicate = self.predicateFrom(
          searchText: searchText, filterPredicate: filterPredicate)
        self.collectionViewBooks.accept(
          realm.objects(Book.self).filter(predicate).sorted(byKeyPath: "createdAt"))
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
    NotificationCenter.default.rx.notification(filterChangedNotificationName, object: nil)
      .subscribe(onNext: { notification in
        if let filter = notification.userInfo?["filter"] as? Filter {
          log.info("Filter selected: \(filter.name), \(filter.predicate)")
          self.filter.accept(filter)
        } else {
          log.error("Unsupported userInfo from filterChangedNotification")
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
      NSDocumentController.shared.openDocument(withContentsOf: url, display: false) {
        (document, documentWasAlreadyOpen, error) in
        if let error = error {
          // TODO: show error dialog
          log.error("Error while open a book at \(url.path): \(error)")
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
            if bookmarkDataIsStale {
              do {
                let realm = try Realm()
                try realm.write {
                  log.info("Regenerate book.bookmark of \(url.path)")
                  book.bookmark = try url.bookmarkData(options: [.suitableForBookmarkFile])
                }
              } catch {
                log.error("error while update book: \(error)")
              }
            }
            document.makeWindowControllers()
            document.showWindows()
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

  // MARK: - NSMenu for NSTableView
  @IBAction func openViewer(_ sender: Any) {
    if let book = self.selectedBook() {
      self.open(book)
    }
  }

  @IBAction func showFileInFinder(_ sender: Any) {
    if let book = self.selectedBook() {
      var bookmarkDataIsStale = false
      if let url = try? book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
      } else {
        // TODO: show error dialog
        self.showModalDialog(message: "", information: "")
      }
    }
  }

  @IBAction func deleteFromLibrary(_ sender: Any) {
    if let book = self.selectedBook() {
      // TODO: show error dialog
      Observable.from([book])
        .subscribe(Realm.rx.delete())
        .disposed(by: self.disposeBag)
    }
  }

  func selectedBook() -> Book? {
    if self.collectionViewStyle.value == .collection {
      if let indexPath = self.collectionView.selectionIndexPaths.first {
        return self.collectionViewBooks.value![indexPath.item]
      }
    } else {
      let index = self.tableView.clickedRow
      if index >= 0 {
        return self.tableViewBooks.value![index]
      }
    }
    return nil
  }

  // MARK: NSMenuItemValidation
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(openViewer(_:)) || selector == #selector(showFileInFinder(_:))
      || selector == #selector(deleteFromLibrary(_:))
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
extension MainViewController: NSTableViewDataSource {
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
    let dropFileCount =
      info.draggingPasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [
          .urlReadingFileURLsOnly: 1,
          .urlReadingContentsConformToTypes: ZipDocument.UTIs + PdfDocument.UTIs,
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
    if let dropFileURLs = info.draggingPasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [
        .urlReadingFileURLsOnly: 1,
        .urlReadingContentsConformToTypes: ZipDocument.UTIs + PdfDocument.UTIs,
      ])
      as? [URL]
    {

      let books: [Book] = dropFileURLs.compactMap { (fileURL) in
        let book = Book()
        guard let _ = try? book.setURL(fileURL) else {
          log.error("Error while create bookmarkData from \(fileURL.path)")
          return nil
        }
        return book
        // TODO: Validate whether file contains one or more images? for example get thumbnail
        //guard let document = try? NSDocumentController.shared.makeDocument(withContentsOf: fileURL, ofType: ZipDocument.UTI) else {
        //log.info("Can not open with ZipDocument")
        //return
        //}
      }
      Observable.of(books)
        .subscribe(Realm.rx.add())
        .disposed(by: self.disposeBag)
      return true
    }
    return false
  }
}

// MARK: NSTableViewDelegate
extension MainViewController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
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
extension MainViewController: NSCollectionViewDataSource {
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
    if let data = book.thumbnailData, let thumbnail = NSImage(data: data) {
      //log.debug("THUMBNAIL SIZE \(thumbnail.representations.first!.pixelsWide) x \(thumbnail.representations.first!.pixelsHigh)")
      item.imageView?.image = thumbnail
    } else {
      // TODO: Use more user friendly image
      item.imageView?.image = NSImage(named: NSImage.bookmarksTemplateName)
    }
    return item
  }
}

// MARK: NSCollectionViewDelegate
extension MainViewController: NSCollectionViewDelegate {
  func collectionView(
    _ collectionView: NSCollectionView,
    validateDrop draggingInfo: NSDraggingInfo,
    proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>,
    dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>
  ) -> NSDragOperation {
    let dropFileCount =
      draggingInfo.draggingPasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [
          .urlReadingFileURLsOnly: 1,
          .urlReadingContentsConformToTypes: ZipDocument.UTIs + PdfDocument.UTIs,
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
    if let dropFileURLs = draggingInfo.draggingPasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [
        .urlReadingFileURLsOnly: 1,
        .urlReadingContentsConformToTypes: ZipDocument.UTIs + PdfDocument.UTIs,
      ])
      as? [URL]
    {

      let books: [Book] = dropFileURLs.compactMap { (fileURL) in
        let book = Book()
        guard let _ = try? book.setURL(fileURL) else {
          log.error("Error while create bookmarkData from \(fileURL.path)")
          return nil
        }
        return book
        // TODO: Validate whether file contains one or more images? for example get thumbnail
        //guard let document = try? NSDocumentController.shared.makeDocument(withContentsOf: fileURL, ofType: ZipDocument.UTI) else {
        //log.info("Can not open with ZipDocument")
        //return
        //}
      }
      Observable.of(books)
        .subscribe(Realm.rx.add())
        .disposed(by: self.disposeBag)
    }
    return false
  }
}
