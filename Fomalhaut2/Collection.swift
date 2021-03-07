// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import RealmSwift

let collectionChangedNotificationName = Notification.Name("collectionChanged")
let collectionDeleteNotificationName = Notification.Name("collectionDelete")

class Collection: Object, Encodable {
  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var name = ""
  @objc dynamic var createdAt: Date = Date()
  let books = List<Book>()

  override static func primaryKey() -> String? {
    return "id"
  }

  enum CodingKeys: String, CodingKey {
    case id, name, createdAt, books
  }
}
