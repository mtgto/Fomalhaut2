// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift

class Book: Object {
  @objc dynamic var filename: String = ""
  @objc dynamic var bookmark: Data = Data()
  @objc dynamic var readCount: Int = 0
  @objc dynamic var lastPageIndex: Int = 0
  @objc dynamic var createdAt: Date = Date()

  func resolveURL(bookmarkDataIsStale: inout Bool) throws -> URL {
    return try URL(
      resolvingBookmarkData: self.bookmark, options: [.withoutMounting, .withoutUI],
      bookmarkDataIsStale: &bookmarkDataIsStale)
  }
}
