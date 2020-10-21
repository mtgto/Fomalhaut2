// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

// Dirty hack: select initially first child of NSOutlineView
// https://gist.github.com/mrjjwright/218405
// It is easy to select first parent of NSOutlineView (index == 0)
class FilterListView: NSOutlineView {
  override func becomeFirstResponder() -> Bool {
    if self.numberOfSelectedRows == 0 {
      self.selectRowIndexes(IndexSet([1]), byExtendingSelection: false)
    }
    return super.becomeFirstResponder()
  }
}
