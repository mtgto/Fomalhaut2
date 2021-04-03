// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

extension NSView {
  @IBInspectable var backgroundColor: NSColor? {
    get {
      guard let backgroundColor = layer?.backgroundColor else {
        return nil
      }
      return NSColor(cgColor: backgroundColor)
    }
    set {
      wantsLayer = true
      layer?.backgroundColor = newValue?.cgColor
    }
  }
}
