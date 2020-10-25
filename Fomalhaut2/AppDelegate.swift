// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import XCGLogger

let log = XCGLogger.default

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Remove main window from window list of Window menu
    // Setting isExcludedFromWindowsMenu in BookWindowController#viewDidLoad is ignored...
    NSApp.windows.first?.isExcludedFromWindowsMenu = true
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    NSDocumentController.shared.openDocument(
      withContentsOf: URL(fileURLWithPath: filename), display: true
    ) { (document, documentWasAlreadyOpen, error) in

    }
    return true
  }

  @IBAction func showLibraryWindow(_ sender: Any) {
    NSApp.windows.first?.makeKeyAndOrderFront(sender)
  }

  @IBAction func openWebsite(_ sender: Any) {
    NSWorkspace.shared.open(URL(string: "https://github.com/mtgto/Fomalhaut2")!)
  }
}
