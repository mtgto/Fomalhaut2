import Cocoa
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
    let entry = self.entries[page]
    var rawData = Data()
    do {
      _ = try self.archive!.extract(entry) { (data) in
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
