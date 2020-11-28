// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import RealmSwift

let collectionChangedNotificationName = Notification.Name("collectionChanged")
let collectionWillDeleteNotificationName = Notification.Name("collectionWillDelete")

class Collection: Object {
  @objc dynamic var id: String = UUID().uuidString
  @objc dynamic var name = ""
  @objc dynamic var createdAt: Date = Date()
  let books = List<Book>()

  override static func primaryKey() -> String? {
    return "id"
  }
}
