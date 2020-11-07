// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

enum PageOrder {
  case ltr, rtl
}

enum BookAccessibleError: Error {
  case brokenFile
}

protocol BookAccessible where Self: NSDocument {
  func pageCount() -> Int

  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, Error>) -> Void)

  func lastPageIndex() -> Int?

  func lastPageOrder() -> PageOrder?

  func shiftedSignlePage() -> Bool?
}
