// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift

// Base Document class
class BookDocument: NSDocument {
  var book: Book?  // should be frozen
  static let thumbnailMaxWidth: Int = 220  // size of pixel
  static let thumbnailMaxHeight: Int = 340

  override func makeWindowControllers() {
    // Returns the Storyboard that contains your Document window.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Book"), bundle: nil)
    let windowController =
      storyboard.instantiateController(
        withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller"))
      as! NSWindowController
    //windowController.document = self
    windowController.contentViewController?.representedObject = self
    if let book = self.book {
      windowController.windowFrameAutosaveName = "Book\(book.id)"
    }
    self.addWindowController(windowController)
  }

  func storeViewerStatus(
    lastPageIndex: Int, isRightToLeft: Bool, shiftedSignlePage: Bool, manualViewHeight: CGFloat?
  ) throws {
    if let selfBook = self.book {
      let realm = try Realm()
      if let book = realm.object(ofType: Book.self, forPrimaryKey: selfBook.id) {
        try realm.write {
          book.lastPageIndex = lastPageIndex
          book.isRightToLeft = isRightToLeft
          book.shiftedSignlePage = shiftedSignlePage
          book.manualViewHeight.value = manualViewHeight.flatMap(Double.init)
          if selfBook.pageCount == 0 {
            if let accessible = self as? BookAccessible {
              book.pageCount = accessible.pageCount()
            }
          }
        }
      }
    }
  }

  override func read(from url: URL, ofType typeName: String) throws {
    let realm = try Realm()
    if let book = realm.objects(Book.self).filter("filePath = %@", url.path).first {
      try realm.write {
        book.readCount = book.readCount + 1
      }
      self.book = book.freeze()
    } else {
      let book = Book()
      book.readCount = 1
      try book.setURL(url)
      try realm.write {
        realm.add(book)
      }
      self.book = book.freeze()
    }
  }

  func setBookThumbnail(_ image: NSImage) throws {
    if let data = image.resizedImageFixedAspectRatio(
      maxPixelsWide: BookDocument.thumbnailMaxWidth, maxPixelsHigh: BookDocument.thumbnailMaxHeight)
    {
      let realm = try Realm()
      if let book = realm.object(ofType: Book.self, forPrimaryKey: self.book!.id) {
        try realm.write {
          book.thumbnailData = data
        }
      }
    }
  }
}
