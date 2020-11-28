// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

final class ImageCacheKey: NSObject {
  private let archiveURL: URL
  private let pageIndex: Int

  init(archiveURL: URL, pageIndex: Int) {
    self.archiveURL = archiveURL
    self.pageIndex = pageIndex
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? ImageCacheKey else {
      return false
    }
    return self.pageIndex == other.pageIndex && self.archiveURL == other.archiveURL
  }

  override var hash: Int {
    var hasher = Hasher()
    hasher.combine(self.archiveURL)
    hasher.combine(self.pageIndex)
    return hasher.finalize()
  }
}

let imageCache = NSCache<ImageCacheKey, NSImage>()
