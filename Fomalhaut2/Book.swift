// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift

class Book: Object {
  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var name: String = ""
  @objc dynamic var filePath: String = ""
  @objc dynamic var bookmark: Data = Data()
  @objc dynamic var readCount: Int = 0
  @objc dynamic var createdAt: Date = Date()
  @objc dynamic var like: Bool = false
  @objc dynamic var pageCount: Int = 0
  // for viewer information
  @objc dynamic var isRightToLeft: Bool = true
  @objc dynamic var lastPageIndex: Int = 0
  @objc dynamic var shiftedSignlePage: Bool = false
  let manualViewHeight = RealmOptional<Double>()
  // PNG data
  @objc dynamic var thumbnailData: Data? = nil

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
    self.name = url.lastPathComponent
    let bookmark = try url.bookmarkData(options: [.suitableForBookmarkFile])
    self.bookmark = bookmark
  }
}
