// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import Foundation
import SevenZip

public class SevenZipArchiver: Archiver {
  public static let utis: [String] = ["org.7-zip.7-zip-archive", "net.mtgto.Fomalhaut2.cb7"]
  private let archive: Archive
  private let entries: [Entry]
  private let operationQueue: OperationQueue

  public required init?(url: URL) {
    do {
      self.archive = try Archive(fileURL: url)
      self.entries = self.archive.entries.sorted { (lhs, rhs) -> Bool in
        lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
      }.filter { (entry) -> Bool in
        if entry.path.contains("__MACOSX/") || entry.uncompressedSize == 0 {
          return false
        }
        let path = entry.path.lowercased()
        return path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png")
          || path.hasSuffix(".gif") || path.hasSuffix(".bmp") || path.hasSuffix(".tif") || path.hasSuffix(".tiff")
      }
      self.operationQueue = OperationQueue()
      self.operationQueue.maxConcurrentOperationCount = 1
    } catch {
      log.info("Failed to open with LzmaArchiver: \(error)")
      return nil
    }
  }

  public func pageCount() -> Int {
    return self.entries.count
  }

  public func image(at page: Int, completion: @escaping (Result<NSImage, ArchiverError>) -> Void) {
    self.operationQueue.addOperation {
      do {
        let entry = self.entries[page]
        let data = try self.archive.extract(entry: entry)
        guard let image = NSImage(data: data) else {
          completion(.failure(.brokenFile))
          return
        }
        completion(.success(image))
      } catch {
        log.error("Error while extracting at \(page): \(error)")
        completion(.failure(.brokenFile))
      }
    }
  }

}
