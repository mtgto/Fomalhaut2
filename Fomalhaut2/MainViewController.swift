// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRealm
import RxSwift

class MainViewController: NSSplitViewController, NSTableViewDataSource, NSTableViewDelegate,
  NSMenuItemValidation
{

  private var books: Results<Book>!
  private let disposeBag = DisposeBag()
  @IBOutlet weak var tableView: NSTableView!

  override func viewDidLoad() {
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
    super.viewDidLoad()
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
            if let document = document as? ZipDocument {
              document.book = book
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
        self.showModalDialog(message: "", information: "")
      }
    }
  }

  @IBAction func deleteFromLibrary(_ sender: Any) {
    let index = self.tableView.clickedRow
    if index >= 0 {
      let book = self.books[index]
      // TODO: show error dialog
      Observable.from([book])
        .subscribe(Realm.rx.delete())
        .disposed(by: self.disposeBag)
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
    let book = self.books[row]
    if let columnIdentifier = tableColumn?.identifier {
      switch columnIdentifier {
      case NSUserInterfaceItemIdentifier("file"):
        return book.filename
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

  // MARK: NSTableViewDelegate
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
  {
    guard let identifier = tableColumn?.identifier,
      let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
    else {
      return nil
    }
    switch identifier.rawValue {
    case "file":
      cellView.textField?.stringValue = self.books[row].filename
    case "view":
      cellView.textField?.stringValue = String(self.books[row].readCount)
    default:
      break
    }

    return cellView
  }
}

extension NSTableView {
  func applyChangeset(_ changes: RealmChangeset) {
    beginUpdates()
    removeRows(at: IndexSet(changes.deleted))
    insertRows(at: IndexSet(changes.inserted))
    reloadData(forRowIndexes: IndexSet(changes.updated), columnIndexes: [0, 1])
    endUpdates()
  }
}
