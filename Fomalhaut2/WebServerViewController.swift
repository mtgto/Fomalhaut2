// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxSwift

class WebServerViewController: NSViewController {
  static let webServerPortKey = "webServerPort"
  private let webServer = WebServer()
  private let disposeBag = DisposeBag()
  @IBOutlet weak var portTextField: NSTextField!
  @IBOutlet weak var toggleWebServerButton: NSButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.portTextField.stringValue = String(UserDefaults.standard.integer(forKey: WebServerViewController.webServerPortKey))
    self.toggleWebServerButton.rx.tap
      .scan(false) { started, newValue in
        if started {
          log.info("Stop WebServer...")
          self.webServer.stop()
          self.portTextField.isEditable = true
          self.toggleWebServerButton.title = NSLocalizedString("Start", comment: "Start")
          return false
        } else {
          if let portNumber = UInt16(self.portTextField.stringValue) {
            log.info("Start WebServer (port = \(portNumber))")
            do {
              try self.webServer.start(port: portNumber)
              UserDefaults.standard.set(Int(portNumber), forKey: WebServerViewController.webServerPortKey)
              self.portTextField.isEditable = false
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
  
  @IBAction func cancel(_ sender: Any) {
    self.webServer.stop()
    self.presentingViewController?.dismiss(self)
  }
}
