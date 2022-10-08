// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxSwift

class MainWindowController: NSWindowController, NSWindowDelegate, NSMenuItemValidation {
  private let disposeBag = DisposeBag()
  @IBOutlet weak var collectionViewStyleSegmentedControl: NSSegmentedControl!
  @IBOutlet weak var searchField: NSSearchField!
  @IBOutlet weak var webSharingButton: NSButton!

  override func windowDidLoad() {
    super.windowDidLoad()

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    let mainStackViewController = self.contentViewController as! MainStackViewController
    let bookCollectionViewController = mainStackViewController.bookCollectionViewController!
    bookCollectionViewController.collectionViewStyle
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { collectionViewStyle in
        self.collectionViewStyleSegmentedControl.selectSegment(
          withTag: collectionViewStyle == .collection ? 0 : 1)
      })
      .disposed(by: self.disposeBag)
    self.searchField.rx.text.asDriver()
      .drive(onNext: { text in
        bookCollectionViewController.searchText.accept(text)
      })
      .disposed(by: self.disposeBag)
    WebSharing.shared.started
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { started in
        if started {
          self.webSharingButton.title = NSLocalizedString("WebSharingStop", comment: "Stop WebSharing")
          self.webSharingButton.image = NSImage(named: "NSStatusAvailable")
        } else {
          self.webSharingButton.title = NSLocalizedString("WebSharingStart", comment: "Start WebSharing…")
          self.webSharingButton.image = nil
        }
      })
      .disposed(by: self.disposeBag)
    // NOTE: windowFrameAutosaveName should be different from NSWindow's autosave name
    self.windowFrameAutosaveName = "MainWindowController"
  }

  @IBAction func updateCollectionViewStyle(_ sender: Any) {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    let bookCollectionViewController = mainStackViewController.bookCollectionViewController!
    if let segmentedControl = sender as? NSSegmentedControl {
      if segmentedControl.selectedSegment == 0 {  // Use CollectionView
        bookCollectionViewController.setCollectionViewStyle(.collection)
      } else {  // Use TableView
        bookCollectionViewController.setCollectionViewStyle(.list)
      }
    }
  }

  // MARK: - MenuItem
  @IBAction func useThumbnailView(_ sender: Any) {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    let bookCollectionViewController = mainStackViewController.bookCollectionViewController!
    bookCollectionViewController.setCollectionViewStyle(.collection)
  }

  @IBAction func useListView(_ sender: Any) {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    let bookCollectionViewController = mainStackViewController.bookCollectionViewController!
    bookCollectionViewController.setCollectionViewStyle(.list)
  }

  @IBAction func addNewCollection(_ sender: Any) {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    let filterListViewController = mainStackViewController.filterListViewController!
    filterListViewController.addNewCollection()
  }

  @IBAction func startWebServer(_ sender: Any) {
    if WebSharing.shared.started.value {
      self.webSharingButton.isEnabled = false
      WebSharing.shared.stop { error in
        DispatchQueue.main.async {
          self.webSharingButton.isEnabled = true
        }
        log.debug("Stopped WebSharing")
        if let error {
          // TODO: Show alert
          log.error("Error while stopping web sharing: \(error)")
        }
      }
    } else {
      let vc = WebSharingViewController(nibName: WebSharingViewController.className(), bundle: nil)
      self.contentViewController?.presentAsSheet(vc)
    }
  }

  @IBAction func openRandomBook(_ sender: Any) {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    mainStackViewController.bookCollectionViewController?.openRandomBook()
  }

  @IBAction func performFindPanelAction(_ sender: Any?) {
    self.searchField.window?.makeFirstResponder(self.searchField)
  }

  func bookCollectionViewController() -> BookCollectionViewController {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    return mainStackViewController.bookCollectionViewController!
  }

  // MARK: - NSMenuItemValidation
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    let mainStackViewController = self.contentViewController as! MainStackViewController
    let bookCollectionViewController = mainStackViewController.bookCollectionViewController!
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(useThumbnailView(_:)) {
      menuItem.state = bookCollectionViewController.collectionViewStyle.value == .collection ? .on : .off
      return true
    } else if selector == #selector(useListView(_:)) {
      menuItem.state = bookCollectionViewController.collectionViewStyle.value == .list ? .on : .off
      return true
    } else if selector == #selector(addNewCollection(_:)) {
      return true
    } else if selector == #selector(startWebServer(_:)) {
      return true
    } else if selector == #selector(openRandomBook(_:)) {
      // TODO: at least one book
      return true
    } else if selector == #selector(performFindPanelAction(_:)) {
      return true
    }
    return false
  }
}
