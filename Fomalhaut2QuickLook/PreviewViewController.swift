// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import Quartz
import Shared
import XCGLogger

let log: XCGLogger = XCGLogger.default

class PreviewViewController: NSViewController, QLPreviewingController {
  @IBOutlet weak var imageView: NSImageView!
  private var archiver: Archiver? = nil

  override var nibName: NSNib.Name? {
    return NSNib.Name("PreviewViewController")
  }

  override func loadView() {
    super.loadView()
    // Do any additional setup after loading the view.
  }

  /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.

        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */

  func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

    // Perform any setup necessary in order to prepare the view.

    // Call the completion handler so Quick Look knows that the preview is fully loaded.
    // Quick Look will display a loading spinner while the completion handler is not called.

    log.info("preparePreviewOfFile \(url.path)")

    guard let archiver = CombineArchiver(from: url, ofType: "") else {
      handler(ArchiverError.brokenFile)
      return
    }
    if archiver.pageCount() == 0 {
      handler(ArchiverError.brokenFile)
      return
    }
    self.archiver = archiver
    self.archiver?.image(
      at: 0,
      completion: { (result) in
        switch result {
        case .success(let image):
          self.imageView.image = image
          handler(nil)
        case .failure(let error):
          handler(error)
        }
      })
  }
}
