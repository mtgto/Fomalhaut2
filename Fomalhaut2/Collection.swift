// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import RealmSwift

let collectionDeleteNotificationName = Notification.Name("collectionDelete")
let collectionStartRenamingNotificationName = Notification.Name("collectionStartRenaming")

class Collection: Object, Encodable {
  @Persisted(primaryKey: true) var id: String = UUID().uuidString
  @Persisted var name = ""
  @Persisted var createdAt: Date = Date()
  @Persisted var order: Int = 0
  @Persisted var books = List<Book>()

  enum CodingKeys: String, CodingKey {
    case id, name, createdAt, books
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.name, forKey: .name)
    try container.encode(self.createdAt, forKey: .createdAt)
    try container.encode(Array(self.books), forKey: .books)
  }
}
