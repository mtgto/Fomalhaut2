// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import Quartz
import RxCocoa
import RxRelay
import RxSwift
import Shared
import XCGLogger

struct LoadedImage {
  let preload: Bool
  let images: [NSImage]
}

let log: XCGLogger = XCGLogger.default
internal let firstImageViewMouseUpNotificationName = Notification.Name("firstImageViewMouseUp")
internal let secondImageViewMouseUpNotificationName = Notification.Name("secondImageViewMouseUp")

class PreviewViewController: NSViewController, QLPreviewingController {
  private var archiver: Archiver? = nil
  let pageCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  let pageOrder: BehaviorRelay<PageOrder> = BehaviorRelay(value: .rtl)
  let currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  let like: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
  var isFullScreen: Bool = false
  private var shiftedSignlePage: Bool = false
  // manualViewHeight has non-nil view height after user resized window
  private var manualViewHeight: CGFloat? = nil
  private(set) var contentSize: CGSize = .zero
  private let disposeBag = DisposeBag()
  private var swipeDeltaX: CGFloat = 0
  private var swipeDeltaY: CGFloat = 0

  @IBOutlet weak var imageStackView: NSStackView!
  @IBOutlet weak var firstImageView: BookImageView!
  @IBOutlet weak var secondImageView: BookImageView!

  override var nibName: NSNib.Name? {
    return NSNib.Name("PreviewViewController")
  }

  override func loadView() {
    super.loadView()
    // Do any additional setup after loading the view.
    self.imageStackView.userInterfaceLayoutDirection = .rightToLeft
    self.firstImageView.notificationName = firstImageViewMouseUpNotificationName
    self.secondImageView.notificationName = secondImageViewMouseUpNotificationName

    NotificationCenter.default.rx.notification(firstImageViewMouseUpNotificationName, object: nil)
      .subscribe(onNext: { notification in
        let shiftPressed = notification.userInfo?[BookImageView.shiftPressed] as? Bool ?? false
        if self.secondImageView.isHidden && !shiftPressed {
          self.forwardPage()
        } else {
          self.backwardPage()
        }
      })
      .disposed(by: self.disposeBag)
    NotificationCenter.default.rx.notification(secondImageViewMouseUpNotificationName, object: nil)
      .subscribe(onNext: { notification in
        let shiftPressed = notification.userInfo?[BookImageView.shiftPressed] as? Bool ?? false
        if shiftPressed {
          self.backwardPage()
        } else {
          self.forwardPage()
        }
      })
      .disposed(by: self.disposeBag)
  }

  private func fetchImages(pageIndex: Int, archiver: Archiver) -> Observable<LoadedImage> {
    return Observable.range(
      start: self.currentPageIndex.value,
      count: min(self.pageCount.value - self.currentPageIndex.value, 16)
    )
    .map { pageIndex in
      self.loadImage(pageIndex: pageIndex, archiver: archiver)
    }
    .concat()
    .buffer(
      timeSpan: .never, count: pageIndex == 0 && !self.shiftedSignlePage ? 1 : 2,
      scheduler: MainScheduler.instance
    )
    .enumerated()
    .map { LoadedImage(preload: $0.index > 0, images: $0.element) }
  }

  private func loadImage(pageIndex: Int, archiver: Archiver) -> Observable<NSImage> {
    return Observable<NSImage>.create { observer in
      archiver.image(at: pageIndex) { (result) in
        switch result {
        case .success(let image):
          observer.onNext(image)
          observer.onCompleted()
          log.debug("success to load image at \(pageIndex)")
        case .failure(let error):
          // do nothing (= skip broken page)
          // TODO: Remember error index in ZipDocument not to reload same error page
          // observer.onError(error)
          log.info("fail to load image at \(pageIndex): \(error)")
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

  private func imageSize(_ image: NSImage) -> NSSize {
    let width = image.representations.first!.pixelsWide
    let height = image.representations.first!.pixelsHigh
    if width == 0 && height == 0 {
      return image.size
    } else {
      return NSSize(width: width, height: height)
    }
  }

  // increment page (two page increment)
  func forwardPage() {
    let incremental = self.currentPageIndex.value == 0 && !self.shiftedSignlePage ? 1 : 2
    if self.currentPageIndex.value + incremental < self.pageCount.value {
      self.currentPageIndex.accept(self.currentPageIndex.value + incremental)
    }
  }

  func forwardSinglePage() {
    if self.canForwardPage() {
      self.currentPageIndex.accept(self.currentPageIndex.value + 1)
      self.shiftedSignlePage = !self.shiftedSignlePage
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
      self.shiftedSignlePage = !self.shiftedSignlePage
    }
  }

  func canForwardPage() -> Bool {
    return self.currentPageIndex.value + 1 < self.pageCount.value
  }

  func canBackwardPage() -> Bool {
    return self.currentPageIndex.value - 1 >= 0
  }

  func firstPage() {
    self.currentPageIndex.accept(0)
  }

  func setPageOrder(_ pageOrder: PageOrder) {
    self.imageStackView.userInterfaceLayoutDirection =
      pageOrder == .rtl ? .rightToLeft : .leftToRight
    self.pageOrder.accept(pageOrder)
  }

  func resizedWindowByManual() {
    self.manualViewHeight = self.view.frame.size.height
  }

  override func scrollWheel(with event: NSEvent) {
    //log.debug("scrollWheel \(event.deltaX), \(event.phase)")
    switch event.phase {
    case .began:
      self.swipeDeltaX = 0
      self.swipeDeltaY = 0
    case .stationary:
      self.swipeDeltaX += event.scrollingDeltaX
      self.swipeDeltaY += event.scrollingDeltaY
      break
    case .changed:
      self.swipeDeltaX += event.scrollingDeltaX
      self.swipeDeltaY += event.scrollingDeltaY
      break
    case .ended:
      if abs(self.swipeDeltaX) > abs(self.swipeDeltaY) {
        if self.swipeDeltaX < -50 {
          // go left page
          self.pageOrder.value == .ltr ? self.forwardPage() : self.backwardPage()
        } else if swipeDeltaX > 50 {
          // go right page
          self.pageOrder.value == .rtl ? self.forwardPage() : self.backwardPage()
        }
      } else {
        if self.swipeDeltaY < -50 {
          self.backwardPage()
        } else if swipeDeltaY > 50 {
          self.forwardPage()
        }
      }
      self.swipeDeltaX = 0
      self.swipeDeltaY = 0
    default:
      self.swipeDeltaX = 0
      self.swipeDeltaY = 0
    }
  }

  /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.

        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */

  func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

    // Perform any setup necessary in order to prepare the view.

    // Call the completion handler so Quick Look knows that the preview is fully loaded.
    // Quick Look will display a loading spinner while the completion handler is not called.

    log.info("preparePreviewOfFile \(url.path)")

    guard let archiver = CombineArchiver(from: url, ofType: "") else {
      handler(ArchiverError.brokenFile)
      return
    }
    self.pageCount.accept(archiver.pageCount())
    if self.pageCount.value == 0 {
      handler(ArchiverError.noImage)
      return
    }
    self.archiver = archiver
    self.currentPageIndex.flatMapLatest { (currentPageIndex) in
      self.fetchImages(pageIndex: currentPageIndex, archiver: archiver)
    }
    .observe(on: MainScheduler.instance)
    .subscribe(
      onNext: { (loadedImage) in
        //log.debug("image = \(loadedImage.images.count), prefetch = \(loadedImage.preload)")
        if loadedImage.preload || loadedImage.images.count == 0 {
          return
        }
        let images = loadedImage.images
        let firstImage: NSImage = images.first!  // TODO: It might be nil if all files are broken
        let secondImage: NSImage? = images.count >= 2 ? images.last : nil
        let firstImageSize = self.imageSize(firstImage)
        let secondImageSize = secondImage != nil ? self.imageSize(secondImage!) : nil
        let contentWidth =
          max(firstImageSize.width, (secondImageSize?.width ?? 0)) * (secondImage != nil ? 2 : 1)
        let contentHeight = max(firstImageSize.height, (secondImageSize?.height ?? 0))

        self.firstImageView.image = firstImage
        if secondImage != nil {
          self.firstImageView.imageAlignment = self.pageOrder.value == .rtl ? .alignLeft : .alignRight
          self.secondImageView.imageAlignment = self.pageOrder.value == .rtl ? .alignRight : .alignLeft
          self.secondImageView.image = secondImage
          self.secondImageView.isHidden = false
        } else {
          self.firstImageView.imageAlignment = .alignCenter
          self.secondImageView.isHidden = true
        }
        /*
        guard let window = self.view.window else {
          log.error("window is nil")
          return
        }
        log.info("window size = \(window.frame.size.width)x\(window.frame.size.height)")
        window.contentAspectRatio = NSSize(width: contentWidth, height: contentHeight)
        // Set window size as screen size
        let resizeRatio: CGFloat
        if let manualViewHeight = self.manualViewHeight {
          resizeRatio = manualViewHeight / contentHeight
        } else {
          resizeRatio = 1.0
        }
        let rect = window.constrainFrameRect(
          NSRect(
            x: window.frame.origin.x,
            y: window.frame.origin.y,
            width: CGFloat(contentWidth * resizeRatio),
            height: CGFloat(contentHeight * resizeRatio)), to: NSScreen.main)
        self.contentSize = rect.size
        window.setContentSize(self.contentSize)
        window.setFrameOrigin(rect.origin)
        if self.isFullScreen {
          window.center()
        }
        log.debug("window.setContentSize(\(rect.size.width), \(rect.size.height))")
         */
      },
      onCompleted: {
        log.debug("onCompleted")
      }
    )
    .disposed(by: self.disposeBag)
    self.currentPageIndex.accept(0)
    handler(nil)
    //    self.archiver?.image(
    //      at: 0,
    //      completion: { (result) in
    //        switch result {
    //        case .success(let image):
    //          //self.imageView.image = image
    //          handler(nil)
    //        case .failure(let error):
    //          handler(error)
    //        }
    //      })
  }
}
