// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation

public enum BookViewStyle: Int {
  // Two pages per view
  case spread = 0
  // Single page per view
  case single = 1

  public static let userDefaultsKey = "bookViewStyle"
  public static let defaultValue: Self = .spread

  public static func defaultBookViewStyle(_ userDefaults: UserDefaults = UserDefaults.standard) -> BookViewStyle {
    let value = userDefaults.integer(forKey: BookViewStyle.userDefaultsKey)
    switch value {
    case spread.rawValue:
      return .spread
    case single.rawValue:
      return .single
    default:
      fatalError("Unknown value: \(value) for BookViewStyle")
    }
  }
}
