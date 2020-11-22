// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import RealmSwift

class Collection: Object {
  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var name = ""
  @objc dynamic var createdAt: Date = Date()
  let books = List<Book>()

  override static func primaryKey() -> String? {
    return "id"
  }
}
