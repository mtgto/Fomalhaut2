// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift

class Book: Object {
  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var filePath: String = ""
  @objc dynamic var bookmark: Data = Data()
  @objc dynamic var readCount: Int = 0
  @objc dynamic var createdAt: Date = Date()
  // for viewer information
  @objc dynamic var isRightToLeft: Bool = true
  @objc dynamic var lastPageIndex: Int = 0
  @objc dynamic var shiftedSignlePage: Bool = false

  var filename: String {
    return URL(fileURLWithPath: self.filePath).lastPathComponent
  }

  override static func primaryKey() -> String? {
    return "id"
  }

  override static func indexedProperties() -> [String] {
    return ["filePath"]
  }

  func resolveURL(bookmarkDataIsStale: inout Bool) throws -> URL {
    return try URL(
      resolvingBookmarkData: self.bookmark, options: [.withoutMounting, .withoutUI],
      bookmarkDataIsStale: &bookmarkDataIsStale)
  }

  func setURL(_ url: URL) throws {
    self.filePath = url.path
    let bookmark = try url.bookmarkData(options: [.suitableForBookmarkFile])
    self.bookmark = bookmark
  }
}
