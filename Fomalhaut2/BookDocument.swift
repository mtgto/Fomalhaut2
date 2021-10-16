// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxSwift
import Shared

class BookDocument: NSDocument {
  private var archiver: Archiver! = nil
  var book: Book?  // should be frozen
  static let thumbnailMaxWidth: Int = 220  // number of pixel of width
  static let thumbnailMaxHeight: Int = 340  // width * (2 ^ 0.5) + delta

  override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
    return true
  }

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
          book.manualViewHeight = manualViewHeight.flatMap(Double.init)
          if selfBook.pageCount == 0 {
            book.pageCount = self.archiver.pageCount()
          }
        }
      }
    }
  }

  func setLike(_ like: Bool) throws {
    if let selfBook = self.book {
      let realm = try Realm()
      if let book = realm.object(ofType: Book.self, forPrimaryKey: selfBook.id) {
        try realm.write {
          book.like = like
        }
      }
    }
  }

  override func read(from url: URL, ofType typeName: String) throws {
    guard let archiver = CombineArchiver(from: url, ofType: typeName) else {
      log.error("Failed to open a file \(url.path)")
      throw ArchiverError.brokenFile
    }
    self.archiver = archiver
    let realm = try Realm()
    if let book = realm.objects(Book.self).filter("filePath = %@", url.path).first {
      self.book = book.freeze()
    } else {
      let book = Book()
      book.isRightToLeft = Preferences.standard.defaultPageOrder == .rtl
      try book.setURL(url)
      try realm.write {
        realm.add(book)
      }
      self.book = book.freeze()
    }
  }

  func image(at page: Int) -> Observable<NSImage> {
    return Observable<NSImage>.create { observer in
      let imageCacheKey = ImageCacheKey(archiveURL: self.fileURL!, pageIndex: page)
      if let image = imageCache.object(forKey: imageCacheKey) {
        log.debug("success to load from cache at \(page)")
        observer.onNext(image)
        observer.onCompleted()
      } else {
        log.debug("fail to load from cache at \(page)")
        self.archiver?.image(
          at: page,
          completion: { (result) in
            switch result {
            case .success(let image):
              imageCache.setObject(image, forKey: imageCacheKey)
              observer.onNext(image)
              observer.onCompleted()
            case .failure(let error):
              observer.onError(error)
            }
          })
      }
      return Disposables.create()
    }.map { image in
      if page == 0 {
        try? self.setBookThumbnail(image)
      }
      return image
    }
  }

  func setBookThumbnail(_ image: NSImage) throws {
    let realm = try Realm()
    if let book = realm.object(ofType: Book.self, forPrimaryKey: self.book!.id) {
      if book.thumbnailData == nil {
        if let data = image.resizedImageFixedAspectRatio(
          maxPixelsWide: BookDocument.thumbnailMaxWidth, maxPixelsHigh: BookDocument.thumbnailMaxHeight)
        {
          try realm.write {
            book.thumbnailData = data
          }
        }
      }
    }
  }

  func pageCount() -> Int {
    return self.archiver.pageCount()
  }

  func lastPageIndex() -> Int? {
    return self.book?.lastPageIndex
  }

  func isLike() -> Bool? {
    return self.book?.like
  }

  func lastPageOrder() -> PageOrder? {
    guard let book = self.book else {
      return nil
    }
    return book.isRightToLeft ? .rtl : .ltr
  }

  func shiftedSignlePage() -> Bool? {
    return book?.shiftedSignlePage
  }
}
