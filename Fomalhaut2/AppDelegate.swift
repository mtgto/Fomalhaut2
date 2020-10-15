import Cocoa
import XCGLogger

let log = XCGLogger.default

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
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

}
