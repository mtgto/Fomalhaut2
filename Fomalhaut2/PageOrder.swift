// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation

enum PageOrder: Int {
  case ltr = 1
  case rtl = 0

  static let pageOrderKey = "pageOrder"
  static let defaultPageOrder = 0  // default is right-to-left

  static func defaultPageOrder(_ userDefaults: UserDefaults = UserDefaults.standard) -> PageOrder {
    let value = userDefaults.integer(forKey: PageOrder.pageOrderKey)
    switch value {
    case rtl.rawValue:
      return .rtl
    case ltr.rawValue:
      return .ltr
    default:
      fatalError("Unknown value: \(value)")
    }
  }
}
