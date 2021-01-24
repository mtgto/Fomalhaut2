// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import Unrar

class RarArchiver: Archiver {
  static let utis: [String] = ["com.rarlab.rar-archive", "net.mtgto.Fomalhaut2.cbr"]
  private let fileURL: URL
  private let entries: [Entry]
  private let operationQueue: OperationQueue

  init?(url: URL) {
    self.fileURL = url
    let archive = Archive(fileURL: url)
    do {
      self.entries = try archive.entries().filter({ (entry) -> Bool in
        let path = entry.fileName.lowercased()
        return path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png")
          || path.hasSuffix(".gif") || path.hasSuffix(".bmp")
      })
    } catch {
      log.warning("Error while load Rar archive \(error)")
      return nil
    }
    if self.entries.isEmpty {
      return nil
    }
    self.operationQueue = OperationQueue()
    self.operationQueue.maxConcurrentOperationCount = 1
  }

  func pageCount() -> Int {
    return self.entries.count
  }

  func image(at page: Int, completion: @escaping (Result<NSImage, BookAccessibleError>) -> Void) {
    self.operationQueue.addOperation {
      let entry = self.entries[page]
      let archive = Archive(path: self.fileURL.path)
      do {
        let data = try archive.extract(entry)
        guard let image = NSImage(data: data) else {
          completion(.failure(BookAccessibleError.brokenFile))
          return
        }
        completion(.success(image))
      } catch {
        log.info("Error while extracting at \(page): \(error)")
        completion(.failure(BookAccessibleError.brokenFile))
      }
    }
  }
}
