// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxSwift
import Shared

let log = Shared.log

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet weak var webSharingMenuItem: NSMenuItem!
  private let disposeBag = DisposeBag()

  override init() {
    super.init()
    // Set defaults before NSViewController.viewDidLoad
    UserDefaults.standard.register(defaults: [
      BookCollectionViewController.collectionTabViewInitialIndexKey: 0,
      BookCollectionViewController.collectionOrderKey: CollectionOrder.createdAt.rawValue,
      WebSharingViewController.webServerPortKey: 8080,
      WebSharingViewController.webServerAutoSuspendKey: true,
      PageOrder.userDefaultsKey: PageOrder.defaultValue.rawValue,
      FilterListViewController.selectedCollectionContentIdKey: "all",  // Filter.id | Collection.id
      CollectionViewHeaderView.itemSizeIndexKey: 2,
      SpreadPageViewController.showPageNumberKey: true,
      BookViewStyle.userDefaultsKey: BookViewStyle.defaultValue.rawValue,
      SpreadPageViewController.keepFirstImageWindowSizeKey: false,
    ])
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Remove main window from window list of Window menu
    // Setting isExcludedFromWindowsMenu in BookWindowController#viewDidLoad is ignored...
    NSApp.windows.first?.isExcludedFromWindowsMenu = true
    do {
      try Schema.shared.migrate()
    } catch {
      let alert = NSAlert()
      alert.messageText = NSLocalizedString(
        "DatabaseBrokenErrorMessageText", comment: "Database is broken")
      alert.informativeText = String(
        format: NSLocalizedString(
          "DatabaseBrokenInformativeText", comment: "Confirm your app is latest"),
        error.localizedDescription)
      alert.alertStyle = .critical
      alert.runModal()
      NSApp.terminate(nil)
    }
    WebSharing.shared.started
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { started in
        if started {
          self.webSharingMenuItem.title = NSLocalizedString("WebSharingStop", comment: "Stop WebSharing")
        } else {
          self.webSharingMenuItem.title = NSLocalizedString("WebSharingStart", comment: "Start WebSharing…")
        }
      })
      .disposed(by: self.disposeBag)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    // wait until schema migration is completed
    Schema.shared.state
      .skip { $0 != .finish }
      .subscribe(onNext: { _ in
        NSDocumentController.shared.openDocument(
          withContentsOf: URL(fileURLWithPath: filename), display: true
        ) { (document, documentWasAlreadyOpen, error) in
          // do nothing
        }
      })
      .disposed(by: self.disposeBag)
    return true
  }

  @IBAction func showLibraryWindow(_ sender: Any) {
    // TODO: Search by identifier?
    NSApp.windows.first?.makeKeyAndOrderFront(sender)
  }

  @IBAction func openWebsite(_ sender: Any) {
    NSWorkspace.shared.open(URL(string: "https://github.com/mtgto/Fomalhaut2")!)
  }
}
