// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import ZIPFoundation

class ZipDocument: NSDocument {
  static let UTI: String = "com.pkware.zip-archive"
  var book: Book?
  private var archive: Archive?
  private lazy var entries: [Entry] = self.archive!.sorted { (lhs, rhs) -> Bool in
    lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
  }.filter { (entry) -> Bool in
    let path = entry.path.lowercased()
    return path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png")
      || path.hasSuffix(".gif") || path.hasSuffix(".bmp")
  }
  private let operationQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    return queue
  }()

  override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
    return true
  }

  override func read(from url: URL, ofType typeName: String) throws {
    guard let archive = Archive(url: url, accessMode: .read, preferredEncoding: .shiftJIS) else {
      throw NSError(domain: "net.mtgto.Fomalhaut2", code: 0, userInfo: nil)
    }
    self.archive = archive
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
    self.addWindowController(windowController)
  }

  override func windowControllerDidLoadNib(_ aController: NSWindowController) {
    super.windowControllerDidLoadNib(aController)
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
  }
}

extension ZipDocument: BookAccessible {

  func pageCount() -> Int {
    return self.entries.count
  }

  // NOTE: This method is not thread safe!
  // cf. https://github.com/weichsel/ZIPFoundation/issues/29
  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, Error>) -> Void) {
    let imageCacheKey = ImageCacheKey(archiveURL: self.archive!.url, pageIndex: page)
    if let image = imageCache.object(forKey: imageCacheKey) {
      log.debug("success to load from cache at \(page)")
      completion(.success(image))
      return
    }
    self.operationQueue.addOperation {
      let entry = self.entries[page]
      var rawData = Data()
      do {
        // Set bufferSize as uncomressed size to reduce the number of calls closure.
        // TODO: assert max bufferSize
        _ = try self.archive!.extract(entry, bufferSize: UInt32(entry.uncompressedSize)) { (data) in
          // log.debug("size of data = \(data.count)")
          rawData.append(data)
          if rawData.count >= entry.uncompressedSize {
            guard let image = NSImage(data: rawData) else {
              completion(.failure(BookAccessibleError.brokenFile))
              return
            }
            imageCache.setObject(image, forKey: imageCacheKey, cost: rawData.count)
            completion(.success(image))
          }
        }
      } catch {
        log.info("Error while extracting at \(page): \(error)")
        completion(.failure(error))
      }
    }
  }

  func lastPageIndex() -> Int? {
    return self.book?.lastPageIndex
  }

  func lastPageOrder() -> PageOrder? {
    guard let book = self.book else {
      return nil
    }
    return book.isRightToLeft ? .rtl : .ltr
  }
}
