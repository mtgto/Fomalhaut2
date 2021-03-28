// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import XCTest

@testable import Fomalhaut2

class CollectionContentTests: XCTestCase {
  func testEquatable() throws {
    let collection: Collection = Collection()
    let collectionCopied = Collection()
    collectionCopied.id = collection.id
    let filter: Filter = Filter(id: "test", name: "testFilter", predicate: NSPredicate(format: "name = \"test\""))
    XCTAssertTrue(CollectionContent.collection(collection) == .collection(collectionCopied))
    XCTAssertTrue(CollectionContent.collection(collection) != .filter(filter))
    XCTAssertTrue(
      CollectionContent.filter(filter)
        != .filter(Filter(id: "testcopy", name: filter.name + "copy", predicate: filter.predicate)))
  }
}
