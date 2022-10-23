// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import RealmSwift

private let threadLocalKey = "net.mtgto.Fomalhaut2.realm"
func threadLocalRealm() throws -> Realm {
  if let realm = Thread.current.threadDictionary[threadLocalKey] as? Realm {
    return realm
  } else {
    let realm = try Realm()
    Thread.current.threadDictionary[threadLocalKey] = realm
    return realm
  }
}
