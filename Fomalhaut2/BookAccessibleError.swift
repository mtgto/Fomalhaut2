// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation

enum BookAccessibleError: Error {
  case brokenFile
  case encrypted
}

extension BookAccessibleError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .brokenFile:
      return NSLocalizedString("ErrorBrokenFile", comment: "File is corrupt or unsupported file type")
    case .encrypted:
      return NSLocalizedString("ErrorEncrypted", comment: "File is encrypted")
    }
  }
}
