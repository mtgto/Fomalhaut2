// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

protocol Archiver {
  func pageCount() -> Int
  func image(at page: Int, completion: @escaping (_ image: Result<NSImage, BookAccessibleError>) -> Void)
}
