// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class BookImageView: NSImageView {
  var notificationName: Notification.Name!
  static let shiftPressed = "shiftPressed"

  override func mouseUp(with event: NSEvent) {
    NotificationCenter.default.post(
      name: self.notificationName,
      object: nil,
      userInfo: [BookImageView.shiftPressed: event.modifierFlags.contains(.shift)])
  }
}
