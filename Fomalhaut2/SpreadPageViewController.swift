// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRelay
import RxSwift

class SpreadPageViewController: NSViewController {
  let pageCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  let pageOrder: BehaviorRelay<PageOrder> = BehaviorRelay(value: .rtl)
  let currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  private let disposeBag = DisposeBag()

  @IBOutlet weak var imageStackView: NSStackView!
  @IBOutlet weak var firstImageView: NSImageView!
  @IBOutlet weak var secondImageView: NSImageView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    // TODO: Use NSStackView#setViews instead of use userInterfaceLayoutDirection for page order?
    self.imageStackView.userInterfaceLayoutDirection = .rightToLeft
  }

  override func viewWillDisappear() {
    super.viewWillDisappear()
    // Update book
    if let document = self.representedObject as? ZipDocument {
      try? document.storeViewerStatus(
        lastPageIndex: self.currentPageIndex.value, isRightToLeft: self.pageOrder.value == .rtl)
    }
  }

  override var representedObject: Any? {
    didSet {
      guard let document = representedObject as? BookAccessible else { return }
      self.pageCount.accept(document.pageCount())
      if let lastPageIndex = document.lastPageIndex() {
        self.currentPageIndex.accept(lastPageIndex)
      }
      if let lastPageOrder = document.lastPageOrder() {
        self.pageOrder.accept(lastPageOrder)
      }

      self.currentPageIndex.flatMapLatest { (currentPageIndex) in
        Observable.range(
          start: self.currentPageIndex.value,
          count: self.pageCount.value - self.currentPageIndex.value
        )
        .flatMap { pageIndex in
          Observable<NSImage>.create { observer in
            document.image(at: pageIndex) { (result) in
              switch result {
              case .success(let image):
                observer.onNext(image)
                observer.onCompleted()
                log.debug("success to load image at \(pageIndex)")
              case .failure(let error):
                log.info("fail to load image at \(pageIndex): \(error)")
                observer.onCompleted()
              // do nothing (= skip broken page)
              // TODO: Remember error index in ZipDocument not to reload same error page
              // observer.onError(error)
              }
            }
            return Disposables.create()
          }
        }
        .take(currentPageIndex == 0 ? 1 : 2)
        .toArray()
      }
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { (images) in
        let firstImage: NSImage = images.first!  // TODO: It might be nil if all files are broken
        let secondImage: NSImage? = images.count >= 2 ? images.last : nil
        let firstImageWidth = firstImage.representations.first!.pixelsWide
        let firstImageHeight = firstImage.representations.first!.pixelsHigh
        let secondImageWidth = secondImage?.representations.first!.pixelsWide
        let secondImageHeight = secondImage?.representations.first!.pixelsHigh
        let contentWidth =
          max(firstImageWidth, (secondImageWidth ?? 0)) * (secondImage != nil ? 2 : 1)
        let contentHeight = max(firstImageHeight, (secondImageHeight ?? 0))

        self.firstImageView.image = firstImage
        if secondImage != nil {
          self.secondImageView.image = secondImage
          self.secondImageView.isHidden = false
        } else {
          self.secondImageView.isHidden = true
        }
        guard let window = self.view.window else {
          log.error("window is nil")
          return
        }
        window.contentAspectRatio = NSSize(width: contentWidth, height: contentHeight)
        // Set window size as screen size
        let rect = window.constrainFrameRect(
          NSRect(
            x: window.frame.origin.x, y: window.frame.origin.y, width: CGFloat(contentWidth),
            height: CGFloat(contentHeight)), to: NSScreen.main)
        window.setContentSize(NSSize(width: rect.size.width, height: rect.size.height))
      })
      .disposed(by: self.disposeBag)
    }
  }

  override func mouseUp(with event: NSEvent) {
    log.info("mouseUp")
    self.forwardPage()
  }

  override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)
    coder.encode(self.currentPageIndex.value, forKey: "currentPageIndex")
    log.info("encodeRestorableState")
  }

  override func restoreState(with coder: NSCoder) {
    super.restoreState(with: coder)
    let lastCurrentPageIndex = coder.decodeInteger(forKey: "currentPageIndex")
    self.currentPageIndex.accept(lastCurrentPageIndex)
    log.info("restoreState: lastCurrentPageIndex = \(lastCurrentPageIndex)")
  }

  // increment page (two page increment)
  func forwardPage() {
    let incremental = self.currentPageIndex.value == 0 ? 1 : 2
    if self.currentPageIndex.value + incremental < self.pageCount.value {
      self.currentPageIndex.accept(self.currentPageIndex.value + incremental)
    }
  }

  func forwardSinglePage() {
    if self.canForwardPage() {
      self.currentPageIndex.accept(self.currentPageIndex.value + 1)
    }
  }

  // decrement page (two page decrement)
  func backwardPage() {
    let decremental = self.currentPageIndex.value == 1 ? 1 : 2
    if self.currentPageIndex.value - decremental >= 0 {
      self.currentPageIndex.accept(self.currentPageIndex.value - decremental)
    }
  }

  func backwardSinglePage() {
    if self.canBackwardPage() {
      self.currentPageIndex.accept(self.currentPageIndex.value - 1)
    }
  }

  func canForwardPage() -> Bool {
    return self.currentPageIndex.value + 1 < self.pageCount.value
  }

  func canBackwardPage() -> Bool {
    return self.currentPageIndex.value - 1 >= 0
  }

  func setPageOrder(_ pageOrder: PageOrder) {
    self.imageStackView.userInterfaceLayoutDirection =
      pageOrder == .rtl ? .rightToLeft : .leftToRight
    self.pageOrder.accept(pageOrder)
  }
}
