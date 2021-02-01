// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxSwift

class BookWindowController: NSWindowController, NSMenuItemValidation, NSWindowDelegate {
  private let disposeBag = DisposeBag()
  @IBOutlet weak var pageControl: NSSegmentedControl!
  @IBOutlet weak var pageOrderControl: NSSegmentedControl!
  @IBOutlet weak var likeButton: NSButton!

  override func windowDidLoad() {
    super.windowDidLoad()
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    Observable.of(spreadPageViewController.currentPageIndex, spreadPageViewController.pageCount)
      .merge()
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { (_) in
        self.pageControl.setEnabled(spreadPageViewController.canBackwardPage(), forSegment: 0)
        self.pageControl.setEnabled(spreadPageViewController.canForwardPage(), forSegment: 1)
      })
      .disposed(by: self.disposeBag)
    spreadPageViewController.pageOrder
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { (pageOrder) in
        self.pageOrderControl.selectSegment(withTag: pageOrder == .rtl ? 0 : 1)
      })
      .disposed(by: self.disposeBag)
    spreadPageViewController.like
      .compactMap { $0 }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { (like) in
        self.likeButton.state = like ? .on : .off
      })
      .disposed(by: self.disposeBag)
    self.likeButton.rx.state
      .subscribe(onNext: { (state) in
        spreadPageViewController.like.accept(state == .on)
      })
      .disposed(by: self.disposeBag)
  }

  override func keyDown(with event: NSEvent) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    if event.keyCode == 125 || event.keyCode == 38 {  // ↓ or j
      spreadPageViewController.forwardPage()
    } else if event.keyCode == 126 || event.keyCode == 40 {  // ↑ or k
      spreadPageViewController.backwardPage()
    } else if event.keyCode == 49 {  // space
      if event.modifierFlags.contains(.shift) {
        spreadPageViewController.backwardPage()
      } else {
        spreadPageViewController.forwardPage()
      }
    } else {
      log.info("keyDown: \(event.keyCode)")
    }
  }

  // MARK: - NSWindowDelegate
  func windowDidEndLiveResize(_ notification: Notification) {
    // Called after user did resize by yourself
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.resizedWindowByManual()
  }

  func window(
    _ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []
  ) -> NSApplication.PresentationOptions {
    return [.fullScreen, .autoHideToolbar, .autoHideMenuBar, .hideDock]
  }

  func windowDidEnterFullScreen(_ notification: Notification) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.isFullScreen = true
  }

  func windowDidExitFullScreen(_ notification: Notification) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.isFullScreen = false
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
    spreadPageViewController.backwardSinglePage()
  }

  @IBAction func firstPage(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.firstPage()
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
    } else if selector == #selector(firstPage(_:)) {
      return true
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
        spreadPageViewController.setPageOrder(.rtl)
      } else {  // left to right
        spreadPageViewController.setPageOrder(.ltr)
      }
    }
  }

  @IBAction func goFirstPage(_ sender: Any) {
    let spreadPageViewController = self.contentViewController as! SpreadPageViewController
    spreadPageViewController.firstPage()
  }
}
