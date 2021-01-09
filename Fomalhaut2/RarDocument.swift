// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import Unrar

class RarDocument: BookDocument {
  static let UTIs: [String] = ["com.rarlab.rar-archive", "net.mtgto.Fomalhaut2.cbr"]
  private var entries: [Entry] = []

  override func read(from url: URL, ofType typeName: String) throws {
    try super.read(from: url, ofType: typeName)
    let archive = Archive(path: url.path)
    self.entries = try archive.entries().filter({ (entry) -> Bool in
      let path = entry.fileName.lowercased()
      return path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png")
        || path.hasSuffix(".gif") || path.hasSuffix(".bmp")
    })
  }
}

extension RarDocument: BookAccessible {
  func pageCount() -> Int {
    return self.entries.count
  }

  func image(at page: Int, completion: @escaping (Result<NSImage, Error>) -> Void) {
    let imageCacheKey = ImageCacheKey(archiveURL: self.fileURL!, pageIndex: page)
    if let image = imageCache.object(forKey: imageCacheKey) {
      log.debug("success to load from cache at \(page)")
      if let selfBook = self.book {
        if page == 0 && selfBook.thumbnailData == nil {
          do {
            try self.setBookThumbnail(image)
          } catch {
            log.error("Error while creating thumbnail: \(error)")
          }
        }
      }
      completion(.success(image))
      return
    }
    let entry = self.entries[page]
    let archive = Archive(path: self.fileURL!.path)
    do {
      let data = try archive.extract(entry)
      guard let image = NSImage(data: data) else {
        completion(.failure(BookAccessibleError.brokenFile))
        return
      }
      if let selfBook = self.book {
        if page == 0 && selfBook.thumbnailData == nil {
          do {
            try self.setBookThumbnail(image)
          } catch {
            log.error("Error while creating thumbnail: \(error)")
          }
        }
      }
      imageCache.setObject(image, forKey: imageCacheKey, cost: data.count)
      completion(.success(image))
    } catch {
      log.info("Error while extracting at \(page): \(error)")
      completion(.failure(error))
    }
  }

  func lastPageIndex() -> Int? {
    return self.book?.lastPageIndex
  }

  func lastPageOrder() -> PageOrder? {
    guard let book = self.book else {
      return nil
    }
    return book.isRightToLeft ? .rtl : .ltr
  }

  func shiftedSignlePage() -> Bool? {
    return book?.shiftedSignlePage
  }
}
