// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import RealmSwift

class Book: Object, Encodable {
  @Persisted(primaryKey: true) var id: String = UUID().uuidString
  @Persisted var name: String = ""
  @Persisted(indexed: true) var filePath: String = ""
  @Persisted var bookmark: Data = Data()
  @Persisted var readCount: Int = 0
  @Persisted var createdAt: Date = Date()
  @Persisted var like: Bool = false
  @Persisted var pageCount: Int = 0
  // for viewer information
  @Persisted var isRightToLeft: Bool = true
  @Persisted var lastPageIndex: Int = 0
  @Persisted var shiftedSinglePage: Bool = false
  @Persisted var manualViewHeight: Double? = nil
  // jpeg data
  @Persisted var thumbnailData: Data? = nil
  @Persisted var viewStyle: Int = 0  // BookViewStyle.rawValue

  static let abbreviateFileNamePattern = try! NSRegularExpression(
    pattern: "\\.(zip|cbz|rar|cbr|pdf|7z|cb7)$", options: .caseInsensitive)
  var displayName: String {
    return Book.abbreviateFileNamePattern.stringByReplacingMatches(
      in: self.name, options: [], range: NSMakeRange(0, self.name.utf16.count), withTemplate: "")
  }

  enum CodingKeys: String, CodingKey {
    case id, name, readCount, like, pageCount, isRightToLeft, viewStyle
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.displayName, forKey: .name)
    try container.encode(self.readCount, forKey: .readCount)
    try container.encode(self.like, forKey: .like)
    try container.encode(self.pageCount, forKey: .pageCount)
    try container.encode(self.isRightToLeft, forKey: .isRightToLeft)
    try container.encode(self.viewStyle, forKey: .viewStyle)
  }

  func resolveURL(bookmarkDataIsStale: inout Bool) throws -> URL {
    return try URL(
      resolvingBookmarkData: self.bookmark, options: [.withoutMounting, .withSecurityScope],
      bookmarkDataIsStale: &bookmarkDataIsStale)
  }

  func setURL(_ url: URL) throws {
    self.name = url.lastPathComponent
    let bookmark = try url.bookmarkData(options: [
      .withSecurityScope, .securityScopeAllowOnlyReadAccess,
    ])
    var bookmarkDataIsStale = false
    do {
      let securityScopedURL = try URL(
        resolvingBookmarkData: bookmark, options: [.withoutMounting, .withSecurityScope],
        bookmarkDataIsStale: &bookmarkDataIsStale)
      self.filePath = securityScopedURL.path
    } catch {
      log.error("Error while converting Security-Scoped URL: \(error)")
      self.filePath = url.path
    }
    self.bookmark = bookmark
  }
}
