// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

public class BookImageView: NSImageView {
  public var notificationName: Notification.Name!
  public static let shiftPressed = "shiftPressed"

  public override func mouseUp(with event: NSEvent) {
    NotificationCenter.default.post(
      name: self.notificationName,
      object: nil,
      userInfo: [BookImageView.shiftPressed: event.modifierFlags.contains(.shift)])
  }
}
