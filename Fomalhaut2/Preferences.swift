// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation
import Shared

struct Preferences {
  static var standard = Preferences()
  var defaultPageOrder: PageOrder

  init() {
    let userDefaults = UserDefaults.standard
    self.defaultPageOrder = PageOrder.defaultPageOrder(userDefaults)
  }

  mutating func setDefaultPageOrder(_ pageOrder: PageOrder) {
    let userDefaults = UserDefaults.standard
    self.defaultPageOrder = pageOrder
    userDefaults.setValue(pageOrder.rawValue, forKey: PageOrder.userDefaultsKey)
  }
}
