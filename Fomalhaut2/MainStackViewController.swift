// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class MainStackViewController: NSViewController {
  @IBOutlet weak var stackView: NSStackView!

  var mainViewController: MainViewController? {
    for child in self.children {
      if let vc = child as? MainViewController {
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
