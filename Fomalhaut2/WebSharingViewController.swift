// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RxRelay
import RxSwift

class WebSharingViewController: NSViewController {
  static let webServerPortKey = "webServerPort"
  static let webServerAutoSuspendKey = "webServerAutoSuspend"
  private let dateFormatter = DateFormatter()
  private var timeoutDisposable: Disposable? = nil
  private let disposeBag = DisposeBag()
  @IBOutlet weak var portTextField: NSTextField!
  @IBOutlet weak var toggleWebServerButton: NSButton!
  @IBOutlet weak var closeButton: NSButton!
  @IBOutlet weak var openBrowserButton: NSButton!
  @IBOutlet weak var informationLabel: NSTextField!
  @IBOutlet weak var timeoutCheckboxButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.portTextField.stringValue = String(
      UserDefaults.standard.integer(forKey: WebSharingViewController.webServerPortKey))
    self.dateFormatter.locale = .current
    self.dateFormatter.dateStyle = .short
    self.dateFormatter.timeStyle = .short
    self.timeoutCheckboxButton.state =
      UserDefaults.standard.bool(forKey: WebSharingViewController.webServerAutoSuspendKey) ? .on : .off
    self.timeoutCheckboxButton.rx.state
      .subscribe(onNext: { newState in
        UserDefaults.standard.set(
          self.timeoutCheckboxButton.state == .on, forKey: WebSharingViewController.webServerAutoSuspendKey)
      })
      .disposed(by: self.disposeBag)
    self.toggleWebServerButton.rx.tap
      .scan(false) { started, newValue in
        self.timeoutDisposable?.dispose()
        if started {
          log.info("Stop WebServer...")
          WebSharing.shared.stop { (error) in
            DispatchQueue.main.async {
              self.portTextField.isEnabled = true
              self.openBrowserButton.isEnabled = false
              self.toggleWebServerButton.title = NSLocalizedString("Start", comment: "Start")
              self.timeoutCheckboxButton.isEnabled = true
              WebSharing.shared.remoteAddress.accept("")
            }
          }
          return false
        } else {
          if let portNumber = Int(self.portTextField.stringValue) {
            log.info("Start WebServer (port = \(portNumber))")
            if self.timeoutCheckboxButton.state == .on {
              // Close web sharing automatically after 10 minutes since last access
              self.timeoutDisposable = WebSharing.shared.remoteAddress
                .debounce(.seconds(60 * 10), scheduler: MainScheduler.instance)
                .take(1)
                .asSingle()
                .subscribe { _ in
                  self.informationLabel.stringValue = NSLocalizedString("WebSharingTimeout", comment: "")
                  _ = self.toggleWebServerButton.target?.perform(self.toggleWebServerButton.action, with: nil)
                }
              self.timeoutDisposable?.disposed(by: self.disposeBag)
            }
            do {
              try WebSharing.shared.start(port: portNumber)
              self.informationLabel.stringValue = ""
              UserDefaults.standard.set(Int(portNumber), forKey: WebSharingViewController.webServerPortKey)
              self.portTextField.isEnabled = false
              self.openBrowserButton.isEnabled = true
              self.toggleWebServerButton.title = NSLocalizedString("Stop", comment: "Stop")
              self.timeoutCheckboxButton.isEnabled = false
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
    WebSharing.shared.remoteAddress
      .observe(on: MainScheduler.instance)
      .distinctUntilChanged()
      .subscribe(onNext: { remoteAddress in
        log.debug("remoteAddress: \(remoteAddress)")
        if !remoteAddress.isEmpty {
          let information = String(
            format: NSLocalizedString("WebSharingIpAddressInformation", comment: "Last Access from %@ at %@"),
            remoteAddress, self.dateFormatter.string(from: Date()))
          self.informationLabel.stringValue = information
        }
      })
      .disposed(by: self.disposeBag)
  }

  @IBAction func close(_ sender: Any) {
    self.presentingViewController?.dismiss(self)
  }

  @IBAction func openBrowser(_ sender: Any) {
    let port = UserDefaults.standard.integer(forKey: WebSharingViewController.webServerPortKey)
    if let url = URL(string: "http://127.0.0.1:\(port)") {
      NSWorkspace.shared.open(url)
    }
  }
}
