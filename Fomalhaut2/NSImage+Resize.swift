// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

extension NSImage {
  func resize(to size: CGSize) -> NSImage {
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .medium
      draw(
        in: NSRect(origin: .zero, size: size), from: NSRect(origin: .zero, size: self.size),
        operation: .copy, fraction: 1.0)
      newImage.unlockFocus()
    }
    return newImage
  }
}
