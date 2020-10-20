// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class FilterListViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
  // TODO: Use PublishSubject to add/remove filter by user
  private let filters: [Filter] = [Filter(name: "All", books: []), Filter(name: "Unread", books: [])]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
  }
  
  // MARK: - NSOutlineViewDataSource
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      // root
      return "Library"
    }
    return self.filters[index]
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    return false
  }
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return 2
    }
    return 0
  }
  
  func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
    if let filter = item as? Filter {
      return filter.name
    }
    return nil
  }
}
