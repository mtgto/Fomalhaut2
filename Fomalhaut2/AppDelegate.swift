// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxSwift
import XCGLogger

let log = XCGLogger.default

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  private let disposeBag = DisposeBag()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Remove main window from window list of Window menu
    // Setting isExcludedFromWindowsMenu in BookWindowController#viewDidLoad is ignored...
    NSApp.windows.first?.isExcludedFromWindowsMenu = true
    UserDefaults.standard.register(defaults: [
      BookCollectionViewController.collectionTabViewInitialIndexKey: 0,
      WebSharingViewController.webServerPortKey: 8080,
      PageOrder.pageOrderKey: PageOrder.defaultValue.rawValue,
    ])
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
