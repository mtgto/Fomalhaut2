// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

public protocol Archiver {
  static var utis: [String] { get }
  static var extensions: [String] { get }
  func pageCount() -> Int

  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, ArchiverError>) -> Void)
}

public class CombineArchiver: Archiver {
  public static var utis: [String] =
    ZipArchiver.utis + RarArchiver.utis + PdfArchiver.utis + SevenZipArchiver.extensions + FolderArchiver.extensions
  public static var extensions: [String] =
    ZipArchiver.extensions + RarArchiver.extensions + PdfArchiver.extensions + SevenZipArchiver.extensions
  private let archiver: Archiver

  public required init?(from url: URL, ofType typeName: String) {
    let pathExtension = url.pathExtension.lowercased()
    let archiver: Archiver?
    if ZipArchiver.utis.contains(typeName) || ZipArchiver.extensions.contains(pathExtension) {
      archiver = ZipArchiver(url: url)
    } else if RarArchiver.utis.contains(typeName) || RarArchiver.extensions.contains(pathExtension) {
      archiver = RarArchiver(url: url)
    } else if PdfArchiver.utis.contains(typeName) || PdfArchiver.extensions.contains(pathExtension) {
      archiver = PdfArchiver(url: url)
    } else if SevenZipArchiver.utis.contains(typeName) || SevenZipArchiver.extensions.contains(pathExtension) {
      archiver = SevenZipArchiver(url: url)
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

  public func image(at page: Int, completion: @escaping (_ image: Result<NSImage, ArchiverError>) -> Void) {
    self.archiver.image(at: page, completion: completion)
  }
}
