// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

struct Filter: Equatable {
  let name: String
  // TODO: Add Observable, like PublishSubject, to subscribe filtered books
  let books: [Book]
  
  static func == (lhs: Filter, rhs: Filter) -> Bool {
    return lhs.name == rhs.name
  }
}
