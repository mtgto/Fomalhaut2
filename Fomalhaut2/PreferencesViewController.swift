// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class PreferencesViewController: NSViewController {
  @IBOutlet weak var pageOrderPopupButton: NSPopUpButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    let index = Preferences.standard.defaultPageOrder == .rtl ? 0 : 1
    self.pageOrderPopupButton.selectItem(at: index)
  }

  @IBAction func selectPageOrder(_ sender: Any) {
    let pageOrder: PageOrder = self.pageOrderPopupButton.indexOfSelectedItem == 0 ? .rtl : .ltr
    Preferences.standard.setDefaultPageOrder(pageOrder)
  }
}
