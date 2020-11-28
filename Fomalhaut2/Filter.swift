// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

let filterChangedNotificationName = Notification.Name("bookFilterChanged")

struct Filter: Equatable {
  let name: String
  let predicate: String

  static func == (lhs: Filter, rhs: Filter) -> Bool {
    return lhs.name == rhs.name
  }
}
