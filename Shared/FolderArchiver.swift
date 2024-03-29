// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class FolderArchiver: Archiver {
  public static let utis: [String] = ["public.folder"]
  public static let extensions: [String] = []
  private let entries: [URL]

  public init?(url: URL) {
    do {
      let contentUrls = try FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      self.entries =
        contentUrls
        .filter { ["jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff", "webp"].contains($0.pathExtension.lowercased()) }
        .sorted { (lhs, rhs) -> Bool in
          lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
        }
    } catch {
      log.error("Error while fetching folder content: \(error)")
      return nil
    }
  }

  func pageCount() -> Int {
    return self.entries.count
  }

  func image(at page: Int, completion: @escaping (Result<NSImage, ArchiverError>) -> Void) {
    if let image = NSImage(contentsOf: self.entries[page]) {
      completion(.success(image))
    } else {
      log.info("Can not load a image from \(self.entries[page].path)")
      completion(.failure(ArchiverError.brokenFile))
    }
  }
}
