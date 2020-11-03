// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift

// Base Document class
class BookDocument: NSDocument {
  var book: Book?  // should be frozen

  override func makeWindowControllers() {
    // Returns the Storyboard that contains your Document window.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Book"), bundle: nil)
    let windowController =
      storyboard.instantiateController(
        withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller"))
      as! NSWindowController
    //windowController.document = self
    windowController.contentViewController?.representedObject = self
    self.addWindowController(windowController)
  }

  func storeViewerStatus(lastPageIndex: Int, isRightToLeft: Bool, manualViewHeight: CGFloat?) throws
  {
    if let selfBook = self.book {
      let realm = try Realm()
      if let book = realm.object(ofType: Book.self, forPrimaryKey: selfBook.id) {
        try realm.write {
          book.lastPageIndex = lastPageIndex
          book.isRightToLeft = isRightToLeft
          book.manualViewHeight.value = manualViewHeight.flatMap(Double.init)
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
    let maxWidth: CGFloat = 220.0
    let maxHeight: CGFloat = 340.0
    let width: CGFloat
    let height: CGFloat
    let aspectRatio = image.size.height / image.size.width
    if image.size.height / image.size.width > maxHeight / maxWidth {
      width = maxHeight / aspectRatio
      height = maxHeight
    } else {
      width = maxWidth
      height = maxWidth * aspectRatio
    }
    let thumbnail = image.resize(to: CGSize(width: width, height: height))
    if let tiff = thumbnail.tiffRepresentation,
      let data = NSBitmapImageRep(data: tiff)?.representation(
        using: .png, properties: [:])
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
