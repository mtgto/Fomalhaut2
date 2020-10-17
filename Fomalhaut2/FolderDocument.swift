// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class FolderDocument: NSDocument {
  static let UTI: String = "public.folder"
  private var entries: [URL] = []

  override func read(from url: URL, ofType typeName: String) throws {
    do {
      let contentUrls = try FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      self.entries =
        contentUrls
        .filter { ["jpg", "jpeg", "png", "gif", "bmp"].contains($0.pathExtension.lowercased()) }
        .sorted { (lhs, rhs) -> Bool in
          lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
        }
    } catch {
      log.error("Error while fetching folder content: \(error)")
      throw NSError(domain: "net.mtgto.Fomalhaut2", code: 0, userInfo: nil)
    }
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

extension FolderDocument: BookAccessible {
  func pageCount() -> Int {
    return self.entries.count
  }

  func image(at page: Int, completion: @escaping (Result<NSImage, Error>) -> Void) {
    if let image = NSImage(contentsOf: self.entries[page]) {
      completion(.success(image))
    } else {
      log.info("Can not load a image from \(self.entries[page].path)")
      completion(.failure(BookAccessibleError.brokenFile))
    }
  }
}
