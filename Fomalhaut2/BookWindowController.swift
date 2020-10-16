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
    let bookViewController = self.contentViewController as! SpreadPageViewController
    Observable.of(bookViewController.currentPageIndex, bookViewController.pageCount)
      .merge()
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (_) in
        self.pageControl.setEnabled(bookViewController.canBackwardPage(), forSegment: 0)
        self.pageControl.setEnabled(bookViewController.canForwardPage(), forSegment: 1)
      })
      .disposed(by: self.disposeBag)
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 49 {  // space
      let bookViewController = self.contentViewController as! SpreadPageViewController
      if event.modifierFlags.contains(.shift) {
        bookViewController.backwardPage()
      } else {
        bookViewController.forwardPage()
      }
    } else {
      log.info("keyDown: \(event.keyCode)")
    }
  }

  // MARK: - MenuItem
  @IBAction func forwardPage(_ sender: Any) {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    bookViewController.forwardPage()
  }

  @IBAction func backwardPage(_ sender: Any) {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    bookViewController.backwardPage()
  }

  @IBAction func forwardSinglePage(_ sender: Any) {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    bookViewController.forwardSinglePage()
  }

  @IBAction func backwardSinglePage(_ sender: Any) {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    bookViewController.backwardPage()
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(forwardPage(_:)) {
      return bookViewController.canForwardPage()
    } else if selector == #selector(backwardPage(_:)) {
      return bookViewController.canBackwardPage()
    } else if selector == #selector(forwardSinglePage(_:)) {
      return bookViewController.canForwardPage()
    } else if selector == #selector(backwardSinglePage(_:)) {
      return bookViewController.canBackwardPage()
    }
    return false
  }

  // MARK: - Toolbar
  @IBAction func updatePageControl(_ sender: Any) {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    if let segmentedControl = sender as? NSSegmentedControl {
      if segmentedControl.selectedSegment == 0 {
        bookViewController.backwardPage()
      } else {
        bookViewController.forwardPage()
      }
    }
  }

  @IBAction func updatePageOrder(_ sender: Any) {
    let bookViewController = self.contentViewController as! SpreadPageViewController
    if let segmentedControl = sender as? NSSegmentedControl {
      if segmentedControl.selectedSegment == 0 {  // right to left
        bookViewController.setPageOrder(PageOrder.rtl)
      } else {  // left to right
        bookViewController.setPageOrder(PageOrder.ltr)
      }
    }
  }
}
