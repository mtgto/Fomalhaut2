// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import RxRelay

// Selected content in sidebar
enum CollectionContent: Equatable {
  static let selected = BehaviorRelay<CollectionContent?>(value: nil)

  case collection(Collection)
  case filter(Filter)

  var id: String {
    switch self {
    case .collection(let collection):
      return collection.id
    case .filter(let filter):
      return filter.id
    }
  }

  static func == (lhs: CollectionContent, rhs: CollectionContent) -> Bool {
    switch (lhs, rhs) {
    case (let .collection(left), let .collection(right)):
      return left.id == right.id
    case (let .filter(left), let .filter(right)):
      return left == right  // Use Filter#==
    default:
      return false
    }
  }
}
