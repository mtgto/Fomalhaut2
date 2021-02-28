// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

// rawValue is keyPath of Book
enum CollectionOrder: String {
  case createdAt = "createdAt"
  case readCount = "readCount"
  case name = "name"

  var ascending: Bool {
    switch self {
    case .createdAt, .readCount:
      return false
    case .name:
      return true
    }
  }
}
