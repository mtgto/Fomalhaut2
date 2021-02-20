// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

public protocol Archiver {
  func pageCount() -> Int

  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, BookAccessibleError>) -> Void)
}

public class CombineArchiver: Archiver {
  private let archiver: Archiver

  public init?(from url: URL, ofType typeName: String) {
    let pathExtension = url.pathExtension.lowercased()
    let archiver: Archiver?
    if ZipArchiver.utis.contains(typeName) || ["zip", "cbz"].contains(pathExtension) {
      archiver = ZipArchiver(url: url)
    } else if RarArchiver.utis.contains(typeName) || ["rar", "cbr"].contains(pathExtension) {
      archiver = RarArchiver(url: url)
    } else if PdfArchiver.utis.contains(typeName) || ["pdf"].contains(pathExtension) {
      archiver = PdfArchiver(url: url)
    } else if FolderArchiver.utis.contains(typeName) {
      archiver = FolderArchiver(url: url)
    } else {
      log.error("Failed to open a file \(url.path)")
      return nil
    }
    if let archiver = archiver {
      self.archiver = archiver
    } else {
      return nil
    }
  }

  public func pageCount() -> Int {
    return self.archiver.pageCount()
  }

  public func image(at page: Int, completion: @escaping (_ image: Result<NSImage, BookAccessibleError>) -> Void) {
    self.archiver.image(at: page, completion: completion)
  }
}
