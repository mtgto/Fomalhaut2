// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class MainStackViewController: NSViewController {
  @IBOutlet weak var stackView: NSStackView!

  var bookCollectionViewController: BookCollectionViewController? {
    for child in self.children {
      if let vc = child as? BookCollectionViewController {
        return vc
      }
    }
    return nil
  }

  var filterListViewController: FilterListViewController? {
    for child in self.children {
      if let vc = child as? FilterListViewController {
        return vc
      }
    }
    return nil
  }
}
