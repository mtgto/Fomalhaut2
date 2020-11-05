// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class FilterListViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
  private let rootItem = "Library"
  // TODO: Use PublishSubject to add/remove filter by user
  private let filters: [Filter] = [
    Filter(name: "All", predicate: "readCount >= 0"),
    Filter(name: "Unread", predicate: "readCount = 0"),
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
      // root
      return 1
    } else if item is String {
      return self.filters.count
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
    log.error("Unexpected tableColumn. item: \(item)")
    return nil
  }

  func outlineViewSelectionDidChange(_ notification: Notification) {
    //log.info("selectedRow = \(self.filterListView.selectedRow)")
    if let filter = self.filterListView.item(atRow: self.filterListView.selectedRow) as? Filter {
      NotificationCenter.default.post(
        name: filterChangedNotificationName, object: nil, userInfo: ["filter": filter])
    }
  }
}
