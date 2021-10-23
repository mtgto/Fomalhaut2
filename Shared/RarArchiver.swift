// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import Unrar

public class RarArchiver: Archiver {
  public static let utis: [String] = ["com.rarlab.rar-archive", "net.mtgto.Fomalhaut2.cbr"]
  public static let extensions: [String] = ["rar", "cbr"]
  private let fileURL: URL
  private let entries: [Entry]
  private let operationQueue: OperationQueue

  public init?(url: URL) {
    self.fileURL = url
    do {
      let archive = try Archive(fileURL: url)
      self.entries = (try archive.entries())
        .filter({ (entry) -> Bool in
          let path = entry.fileName.lowercased()
          return path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png")
            || path.hasSuffix(".gif") || path.hasSuffix(".bmp") || path.hasSuffix(".tif") || path.hasSuffix(".tiff")
        })
        .sorted(by: { (lhs, rhs) -> Bool in
          return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
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

  public func pageCount() -> Int {
    return self.entries.count
  }

  public func image(at page: Int, completion: @escaping (Result<NSImage, ArchiverError>) -> Void) {
    self.operationQueue.addOperation {
      let entry = self.entries[page]
      do {
        let archive = try Archive(path: self.fileURL.path)
        let data = try archive.extract(entry)
        guard let image = NSImage(data: data) else {
          completion(.failure(ArchiverError.brokenFile))
          return
        }
        completion(.success(image))
      } catch {
        log.info("Error while extracting at \(page): \(error)")
        completion(.failure(ArchiverError.brokenFile))
      }
    }
  }
}
