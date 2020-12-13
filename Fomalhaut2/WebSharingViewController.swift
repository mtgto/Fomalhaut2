// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxSwift

class WebSharingViewController: NSViewController {
  static let webServerPortKey = "webServerPort"
  private let webSharing = WebSharing()
  private let disposeBag = DisposeBag()
  @IBOutlet weak var portTextField: NSTextField!
  @IBOutlet weak var toggleWebServerButton: NSButton!
  @IBOutlet weak var closeButton: NSButton!
  @IBOutlet weak var openBrowserButton: NSButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.portTextField.stringValue = String(
      UserDefaults.standard.integer(forKey: WebSharingViewController.webServerPortKey))
    self.toggleWebServerButton.rx.tap
      .scan(false) { started, newValue in
        if started {
          log.info("Stop WebServer...")
          self.webSharing.stop()
          self.portTextField.isEnabled = true
          self.closeButton.isEnabled = true
          self.openBrowserButton.isEnabled = false
          self.toggleWebServerButton.title = NSLocalizedString("Start", comment: "Start")
          return false
        } else {
          if let portNumber = UInt16(self.portTextField.stringValue) {
            log.info("Start WebServer (port = \(portNumber))")
            do {
              try self.webSharing.start(port: portNumber)
              UserDefaults.standard.set(Int(portNumber), forKey: WebSharingViewController.webServerPortKey)
              self.portTextField.isEnabled = false
              self.closeButton.isEnabled = false
              self.openBrowserButton.isEnabled = true
              self.toggleWebServerButton.title = NSLocalizedString("Stop", comment: "Stop")
              return true
            } catch {
              log.error("Failed to start server: \(error)")
            }
          }
          return false
        }
      }
      .subscribe()
      .disposed(by: self.disposeBag)
  }

  @IBAction func close(_ sender: Any) {
    self.webSharing.stop()
    self.presentingViewController?.dismiss(self)
  }

  @IBAction func openBrowser(_ sender: Any) {
    let port = UserDefaults.standard.integer(forKey: WebSharingViewController.webServerPortKey)
    if let url = URL(string: "http://127.0.0.1:\(port)") {
      NSWorkspace.shared.open(url)
    }
  }
}
