// SPDX-License-Identifier: GPL-3.0-only

// Selected content in sidebar
enum CollectionContent: Equatable {
  case collection(Collection)
  case filter(Filter)

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
