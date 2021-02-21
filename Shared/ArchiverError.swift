// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Foundation

public enum ArchiverError: Error {
  case brokenFile
  case encrypted
}

extension ArchiverError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .brokenFile:
      return NSLocalizedString("ErrorBrokenFile", comment: "File is corrupt or unsupported file type")
    case .encrypted:
      return NSLocalizedString("ErrorEncrypted", comment: "File is encrypted")
    }
  }
}
