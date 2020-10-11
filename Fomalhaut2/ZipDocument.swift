import Cocoa
import Nuke
import ZIPFoundation

class ZipDocument: NSDocument {
  private var archive: Archive?
  private lazy var entries: [Entry] = self.archive!.sorted { (lhs, rhs) -> Bool in
    lhs.path < rhs.path
  }.filter { (entry) -> Bool in
    let path = entry.path.lowercased()
    return path.hasSuffix(".jpg") || path.hasSuffix(".png") || path.hasSuffix(".gif")
      || path.hasSuffix(".bmp")
  }

  override func read(from url: URL, ofType typeName: String) throws {
    guard let archive = Archive(url: url, accessMode: .read, preferredEncoding: .shiftJIS) else {
      throw NSError(domain: "net.mtgto.Fomalhaut2", code: 0, userInfo: nil)
    }
    self.archive = archive
  }

  override func makeWindowControllers() {
    // Returns the Storyboard that contains your Document window.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
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

  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, Error>) -> Void) {
    let imageCacheKey = ImageCacheKey(archiveURL: self.archive!.url, pageIndex: page)
    if let image = imageCache.object(forKey: imageCacheKey) {
      log.debug("success to load from cache")
      completion(.success(image))
      return
    }
    let entry = self.entries[page]
    let decoder = ImageDecoder()
    var rawData = Data()
    do {
      // TODO: assert max bufferSize
      _ = try self.archive!.extract(entry, bufferSize: UInt32(entry.uncompressedSize)) { (data) in
        log.debug("size of data = \(data.count)")
        rawData.append(data)
        if rawData.count >= entry.uncompressedSize {
          guard let imageContainer = decoder.decode(rawData) else {
            completion(.failure(BookAccessibleError.brokenFile))
            return
          }
          imageCache.setObject(imageContainer.image, forKey: imageCacheKey, cost: rawData.count)
          completion(.success(imageContainer.image))
        }
      }
    } catch {
      completion(.failure(error))
    }
  }
}
