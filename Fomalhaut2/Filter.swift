// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

struct Filter: Equatable {
  let id: String
  let name: String
  let predicate: NSPredicate

  static func == (lhs: Filter, rhs: Filter) -> Bool {
    return lhs.id == rhs.id
  }
}
