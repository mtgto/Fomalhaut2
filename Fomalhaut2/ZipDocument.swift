import Cocoa
import ZIPFoundation

class ZipDocument: NSDocument {
  private let archive: Archive
  private lazy var entries: [Entry] = self.archive.sorted { (lhs, rhs) -> Bool in
    lhs.path < rhs.path
  }

  init(contentsOf url: URL, ofType typeName: String) throws {
    guard let archive = Archive(url: url, accessMode: .read, preferredEncoding: .shiftJIS) else {
      throw NSError(domain: NSOSStatusErrorDomain, code: 1, userInfo: nil)
    }
    self.archive = archive
  }

  //  override class var autosavesInPlace: Bool {
  //    return true
  //  }

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

  /*
    override var windowNibName: String? {
        // Override returning the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
        return "ZipDocument"
    }
    */

  override func windowControllerDidLoadNib(_ aController: NSWindowController) {
    super.windowControllerDidLoadNib(aController)
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
  }

  override func data(ofType typeName: String) throws -> Data {
    // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
    // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from data: Data, ofType typeName: String) throws {
    // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
    // Alternatively, you could remove this method and override read(from:ofType:) instead.  If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }
}

extension ZipDocument: BookAccessible {
  func pageCount() -> Int {
    return self.entries.count
  }

  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, Error>) -> Void) {
    let entry = self.entries[page]
    var rawData = Data()
    do {
      _ = try self.archive.extract(entry) { (data) in
        rawData.append(data)
        if rawData.count >= entry.uncompressedSize {
          guard let image = NSImage(data: rawData) else {
            completion(.failure(BookAccessibleError.brokenFile))
            return
          }
          completion(.success(image))
        }
      }
    } catch {
      completion(.failure(error))
    }
  }
}
