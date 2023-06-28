// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation

public enum PageOrder: Int {
  case ltr = 1
  case rtl = 0

  public static let userDefaultsKey = "pageOrder"
  public static let defaultValue: PageOrder = .rtl  // default is right-to-left

  public static func defaultPageOrder(_ userDefaults: UserDefaults = UserDefaults.standard) -> PageOrder {
    let value = userDefaults.integer(forKey: PageOrder.userDefaultsKey)
    switch value {
    case rtl.rawValue:
      return .rtl
    case ltr.rawValue:
      return .ltr
    default:
      fatalError("Unknown value: \(value) for PageOrder")
    }
  }
}
