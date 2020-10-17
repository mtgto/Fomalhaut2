// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRealm
import RxSwift

class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate,
  NSMenuItemValidation
{

  private var books: Results<Book>!
  private let disposeBag = DisposeBag()
  @IBOutlet weak var tableView: NSTableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    self.tableView.registerForDraggedTypes([.fileURL])
    let realm = try! Realm()
    self.books = realm.objects(Book.self).sorted(byKeyPath: "createdAt")
    Observable.changeset(from: self.books)
      .subscribe(onNext: { [unowned self] _, changes in
        if let changes = changes {
          self.tableView.applyChangeset(changes)
        } else {
          self.tableView.reloadData()
        }
      })
      .disposed(by: self.disposeBag)
  }

  func open(_ book: Book) {
    var bookmarkDataIsStale: Bool = false
    do {
      let url = try book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale)
      NSDocumentController.shared.openDocument(withContentsOf: url, display: true) {
        (document, documentWasAlreadyOpen, error) in
        if let error = error {
          // TODO: show error dialog
          log.error("Error while open a book: \(error)")
        } else {
          // TODO: update book information
        }
      }
    } catch {
      // TODO: show error dialog
      log.error("Error while resolve URL from a book: \(error)")
    }
  }

  // Double click the row of TableView
  @IBAction func openBook(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.books[index]
      self.open(book)
    }
  }

  // MARK: - NSMenu for NSTableView
  @IBAction func openViewer(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.books[index]
      self.open(book)
    }
  }

  @IBAction func showFileInFinder(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.books[index]
      var bookmarkDataIsStale = false
      if let url = try? book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
      } else {
        // TODO: show error dialog
      }
    }
  }

  @IBAction func deleteFromLibrary(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.books[index]
      guard let realm = try? Realm() else {
        // TODO: show error dialog
        log.error("Error while open realm")
        return
      }
      do {
        try realm.write {
          realm.delete(book)
        }
      } catch {
        // TODO: show error dialog
        log.error("Error while writing added books: \(error)")
        return
      }
    }
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(openViewer(_:)) || selector == #selector(showFileInFinder(_:))
      || selector == #selector(deleteFromLibrary(_:))
    {
      return self.tableView.clickedRow >= 0
    }
    return false
  }

  // MARK: - NSTableViewDataSource
  func numberOfRows(in: NSTableView) -> Int {
    return self.books.count
  }

  func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int)
    -> Any?
  {
    return self.books[row]
  }

  func tableView(
    _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
    proposedDropOperation dropOperation: NSTableView.DropOperation
  ) -> NSDragOperation {
    let dropFileCount =
      info.draggingPasteboard.readObjects(
        forClasses: [NSURL.self],
        options: [.urlReadingFileURLsOnly: 1, .urlReadingContentsConformToTypes: [ZipDocument.UTI]])?
      .count ?? 0
    if dropFileCount == 0 {
      return []
    }
    return .copy
  }

  func tableView(
    _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
    dropOperation: NSTableView.DropOperation
  ) -> Bool {
    if let dropFileURLs = info.draggingPasteboard.readObjects(
      forClasses: [NSURL.self],
      options: [.urlReadingFileURLsOnly: 1, .urlReadingContentsConformToTypes: [ZipDocument.UTI]])
      as? [URL]
    {

      let books: [Book] = dropFileURLs.compactMap { (fileURL) in
        let book = Book()
        book.filename = fileURL.lastPathComponent
        guard let bookmark = try? fileURL.bookmarkData(options: [.suitableForBookmarkFile]) else {
          log.error("Error while create bookmarkData from \(fileURL.path)")
          return nil
        }
        book.bookmark = bookmark
        return book
        // TODO: Validate whether file contains one or more images? for example get thumbnail
        //guard let document = try? NSDocumentController.shared.makeDocument(withContentsOf: fileURL, ofType: ZipDocument.UTI) else {
        //log.info("Can not open with ZipDocument")
        //return
        //}
      }
      guard let realm = try? Realm() else {
        log.error("Error while open realm")
        return false
      }
      do {
        try realm.write {
          realm.add(books)
        }
      } catch {
        log.error("Error while writing added books: \(error)")
        return false
      }
    }
    return false
  }

  // MARK: NSTableViewDelegate
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    if let cellView = tableView.makeView(
      withIdentifier: NSUserInterfaceItemIdentifier("file"), owner: self) as? NSTableCellView
    {
      cellView.textField?.stringValue = self.books[row].filename
      return cellView
    }
    return nil
  }
}

extension NSTableView {
  func applyChangeset(_ changes: RealmChangeset) {
    beginUpdates()
    removeRows(at: IndexSet(changes.deleted))
    insertRows(at: IndexSet(changes.inserted))
    reloadData(forRowIndexes: IndexSet(changes.updated), columnIndexes: [0])
    endUpdates()
  }
}
