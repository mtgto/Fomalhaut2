// SPDX-License-Identifier: GPL-3.0-only

import Cocoa

class MainWindowController: NSWindowController {
  @IBOutlet weak var collectionViewStyleSegmentedControl: NSSegmentedControl!

  override func windowDidLoad() {
    super.windowDidLoad()

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
  }

  @IBAction func updateCollectionViewStyle(_ sender: Any) {
    let splitViewController = self.contentViewController as! NSSplitViewController
    let mainViewController =
      splitViewController.splitViewItems[1].viewController as! MainViewController
    if let segmentedControl = sender as? NSSegmentedControl {
      if segmentedControl.selectedSegment == 0 {  // Use CollectionView
        mainViewController.setCollectionViewStyle(.collection)
      } else {  // Use TableView
        mainViewController.setCollectionViewStyle(.list)
      }
    }
  }

}
