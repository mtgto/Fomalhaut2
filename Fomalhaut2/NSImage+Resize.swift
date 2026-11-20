// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

extension NSImage {
  func resizedImageFixedAspectRatio(maxPixelsWide: Int, maxPixelsHigh: Int) -> Data? {
    guard self.size.width > 0, self.size.height > 0, maxPixelsWide > 0, maxPixelsHigh > 0 else {
      log.error("Invalid image size or max pixels: \(self.size), \(maxPixelsWide)x\(maxPixelsHigh)")
      return nil
    }
    // Fit into the max size while keeping the aspect ratio. Never enlarge the image (scale <= 1.0).
    let scale = min(
      CGFloat(maxPixelsWide) / self.size.width, CGFloat(maxPixelsHigh) / self.size.height, 1.0)
    let width = max(1, Int((self.size.width * scale).rounded()))
    let height = max(1, Int((self.size.height * scale).rounded()))
    return self.resizedImage(pixelsWide: width, pixelsHigh: height)
  }

  func resizedImage(pixelsWide: Int, pixelsHigh: Int) -> Data? {
    guard pixelsWide > 0, pixelsHigh > 0 else {
      log.error("Invalid pixels: \(pixelsWide)x\(pixelsHigh)")
      return nil
    }
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

  /// Create a JPEG thumbnail from encoded image data with ImageIO.
  /// It does not decode the full-size image. The image is fit into the max size (never enlarged),
  /// EXIF orientation is applied and transparent pixels are composited over white.
  static func thumbnailJPEGData(from data: Data, maxPixelsWide: Int, maxPixelsHigh: Int) -> Data? {
    guard maxPixelsWide > 0, maxPixelsHigh > 0,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int,
      let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int,
      pixelWidth > 0, pixelHeight > 0
    else {
      return nil
    }
    // Orientation 5...8 swaps width and height
    let orientation = (properties[kCGImagePropertyOrientation] as? Int) ?? 1
    let (width, height) = orientation >= 5 ? (pixelHeight, pixelWidth) : (pixelWidth, pixelHeight)
    let scale = min(CGFloat(maxPixelsWide) / CGFloat(width), CGFloat(maxPixelsHigh) / CGFloat(height), 1.0)
    let maxPixelSize = max(1, Int((CGFloat(max(width, height)) * scale).rounded()))
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
      return nil
    }
    // JPEG has no alpha channel. Flatten over white.
    guard
      let context = CGContext(
        data: nil, width: thumbnail.width, height: thumbnail.height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
      return nil
    }
    let rect = CGRect(x: 0, y: 0, width: thumbnail.width, height: thumbnail.height)
    context.setFillColor(CGColor(gray: 1.0, alpha: 1.0))
    context.fill(rect)
    context.draw(thumbnail, in: rect)
    guard let flattened = context.makeImage() else { return nil }
    return NSBitmapImageRep(cgImage: flattened).representation(using: .jpeg, properties: [:])
  }

  func monochrome() -> NSImage? {
    guard let tiffRepresentation = self.tiffRepresentation else { return nil }
    guard let ciImage = CIImage(data: tiffRepresentation) else { return nil }
    guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    guard let outputCIImage = filter.outputImage else { return nil }
    let rep = NSCIImageRep(ciImage: outputCIImage)
    let newImage = NSImage(size: rep.size)
    newImage.addRepresentation(rep)

    return newImage
  }
}
