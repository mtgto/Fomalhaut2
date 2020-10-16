// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxSwift

class BookWindowController: NSWindowController, NSMenuItemValidation {
  private let disposeBag = DisposeBag()
  @IBOutlet weak var pageControl: NSSegmentedControl!
  @IBOutlet weak var pageOrderControl: NSSegmentedControl!

  override func windowDidLoad() {
    super.windowDidLoad()
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    Observable.of(spreadPageViewController.currentPageIndex, spreadPageViewController.pageCount)
      .merge()
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (_) in
        self.pageControl.setEnabled(spreadPageViewController.canBackwardPage(), forSegment: 0)
        self.pageControl.setEnabled(spreadPageViewController.canForwardPage(), forSegment: 1)
      })
      .disposed(by: self.disposeBag)
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 49 {  // space
      let spreadPageViewController = self.contentViewController as! SpreadPageViewController
      if event.modifierFlags.contains(.shift) {
        spreadPageViewController.backwardPage()
      } else {
        spreadPageViewController.forwardPage()
      }
    } else {
      log.info("keyDown: \(event.keyCode)")
    }
  }

  // MARK: - MenuItem
  @IBAction func forwardPage(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.forwardPage()
  }

  @IBAction func backwardPage(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.backwardPage()
  }

  @IBAction func forwardSinglePage(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.forwardSinglePage()
  }

  @IBAction func backwardSinglePage(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.backwardPage()
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(forwardPage(_:)) {
      return spreadPageViewController.canForwardPage()
    } else if selector == #selector(backwardPage(_:)) {
      return spreadPageViewController.canBackwardPage()
    } else if selector == #selector(forwardSinglePage(_:)) {
      return spreadPageViewController.canForwardPage()
    } else if selector == #selector(backwardSinglePage(_:)) {
      return spreadPageViewController.canBackwardPage()
    }
    return false
  }

  // MARK: - Toolbar
  @IBAction func updatePageControl(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    if let segmentedControl = sender as? NSSegmentedControl {
      if segmentedControl.selectedSegment == 0 {
        spreadPageViewController.backwardPage()
      } else {
        spreadPageViewController.forwardPage()
      }
    }
  }

  @IBAction func updatePageOrder(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    if let segmentedControl = sender as? NSSegmentedControl {
      if segmentedControl.selectedSegment == 0 {  // right to left
        spreadPageViewController.setPageOrder(PageOrder.rtl)
      } else {  // left to right
        spreadPageViewController.setPageOrder(PageOrder.ltr)
      }
    }
  }
}
