// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class ProgressViewController: NSViewController {

  @IBOutlet weak var progressIndicator: NSProgressIndicator!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    self.progressIndicator.startAnimation(nil)
  }

}
