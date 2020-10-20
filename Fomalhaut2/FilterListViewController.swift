// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class FilterListViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
  private let rootItem = "Library"
  // TODO: Use PublishSubject to add/remove filter by user
  private let filters: [Filter] = [
    Filter(name: "All", books: []), Filter(name: "Unread", books: []),
  ]
  @IBOutlet weak var filterListView: NSOutlineView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    self.filterListView.expandItem(self.rootItem)
  }

  // MARK: - NSOutlineViewDataSource
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    if item == nil {
      // root
      return self.rootItem
    }
    return self.filters[index]
  }

  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    if item is Filter {
      return false
    }
    return true
  }

  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    if item == nil {
      return 1
    } else if item is String {
      return 2
    } else {
      return 0
    }
  }

  func outlineView(
    _ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?
  ) -> Any? {
    return item
  }

  // MARK: NSOutlineViewDelegate
  func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
    return true
  }

  func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
    if item is String {
      return false
    }
    return true
  }

  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any)
    -> NSView?
  {
    if let filter = item as? Filter {
      let cell =
        outlineView.makeView(
          withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: outlineView)
        as! NSTableCellView
      cell.textField?.stringValue = filter.name
      return cell
    } else if let label = item as? String {
      let cell =
        outlineView.makeView(
          withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: outlineView)
        as! NSTableCellView
      cell.textField?.stringValue = label
      return cell
    }
    log.error("Unexpected tableColumn \(tableColumn), item: \(item)")
    return nil
  }
}
