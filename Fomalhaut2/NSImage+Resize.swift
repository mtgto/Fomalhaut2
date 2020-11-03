// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

extension NSImage {
  func resizedImageFixedAspectRatio(maxPixelsWide: Int, maxPixelsHigh: Int) -> Data? {
    let maxWidth = CGFloat(maxPixelsWide)
    let maxHeight = CGFloat(maxPixelsHigh)
    let width: CGFloat
    let height: CGFloat
    let aspectRatio = self.size.height / self.size.width
    if self.size.height / self.size.width > maxHeight / maxWidth {
      width = maxHeight / aspectRatio
      height = maxHeight
    } else {
      width = maxWidth
      height = maxWidth * aspectRatio
    }
    return self.resizedImage(pixelsWide: Int(width), pixelsHigh: Int(height))
  }

  func resizedImage(pixelsWide: Int, pixelsHigh: Int) -> Data? {
    guard
      let newBitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelsWide,
        pixelsHigh: pixelsHigh,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0)
    else {
      log.error("Failed to retrieve bitmap from image")
      return nil
    }
    newBitmap.size = NSSize(width: pixelsWide, height: pixelsHigh)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newBitmap)
    self.draw(
      in: NSRect(origin: .zero, size: newBitmap.size), from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    return newBitmap.representation(using: .jpeg, properties: [:])
  }
}
