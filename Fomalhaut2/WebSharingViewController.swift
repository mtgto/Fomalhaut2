// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxRelay
import RxSwift

class WebSharingViewController: NSViewController {
  static let webServerPortKey = "webServerPort"
  private let webSharing = WebSharing()
  private let dateFormatter = DateFormatter()
  private let disposeBag = DisposeBag()
  @IBOutlet weak var portTextField: NSTextField!
  @IBOutlet weak var toggleWebServerButton: NSButton!
  @IBOutlet weak var closeButton: NSButton!
  @IBOutlet weak var openBrowserButton: NSButton!
  @IBOutlet weak var informationLabel: NSTextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.portTextField.stringValue = String(
      UserDefaults.standard.integer(forKey: WebSharingViewController.webServerPortKey))
    self.dateFormatter.locale = .current
    self.dateFormatter.dateStyle = .short
    self.dateFormatter.timeStyle = .short
    self.toggleWebServerButton.rx.tap
      .scan(false) { started, newValue in
        if started {
          log.info("Stop WebServer...")
          self.webSharing.stop { (error) in
            DispatchQueue.main.async {
              self.portTextField.isEnabled = true
              self.closeButton.isEnabled = true
              self.openBrowserButton.isEnabled = false
              self.toggleWebServerButton.title = NSLocalizedString("Start", comment: "Start")
            }
          }
          return false
        } else {
          if let portNumber = Int(self.portTextField.stringValue) {
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
    NotificationCenter.default.rx.notification(webSharingIpAddressNotificationName, object: nil)
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { notification in
        if let userInfo = notification.userInfo,
          let ipAddress = userInfo[webSharingIpAddressNotificationUserInfoKey] as? String
        {
          let information = String(
            format: NSLocalizedString("WebSharingIpAddressInformation", comment: "Last Access from %@ at %@"),
            ipAddress, self.dateFormatter.string(from: Date()))
          self.informationLabel.stringValue = information
        }
      })
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
