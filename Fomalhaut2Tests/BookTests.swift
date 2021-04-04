// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import XCTest

@testable import Fomalhaut2

class BookTests: XCTestCase {
  func testDisplayName() throws {
    let book = Book()
    book.name = "あいうえおがぎぐげご.ZIP"
    XCTAssertEqual("あいうえおがぎぐげご", book.displayName)
    book.name = "🍺🍺🍺🍺🍺.cBr"
    XCTAssertEqual("🍺🍺🍺🍺🍺", book.displayName)
  }
}
