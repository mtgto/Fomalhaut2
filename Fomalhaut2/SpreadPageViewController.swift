// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRelay
import RxSwift
import Shared

struct LoadedImage {
  let preload: Bool
  let firstPageIndex: Int  // page index of first page in images
  let images: [NSImage]
}

private let firstImageViewMouseUpNotificationName = Notification.Name("firstImageViewMouseUp")
private let secondImageViewMouseUpNotificationName = Notification.Name("secondImageViewMouseUp")

class SpreadPageViewController: NSViewController {
  static let showPageNumberKey = "showPageNumber"
  static let keepFirstImageWindowSizeKey = "keepFirstImageWindowSize"
  let pageCount: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  let pageOrder: BehaviorRelay<PageOrder> = BehaviorRelay(value: .rtl)
  let viewStyle: BehaviorRelay<BookViewStyle> = BehaviorRelay(value: .spread)
  let currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  let like: BehaviorRelay<Bool?> = BehaviorRelay(value: nil)
  var isFullScreen: Bool = false
  private let showPageNumber: BehaviorRelay<Bool> = BehaviorRelay(value: true)
  private var shiftedSinglePage: Bool = false
  // manualViewHeight has non-nil view height after user resized window
  private var manualViewHeight: CGFloat? = nil
  private(set) var contentSize: CGSize = .zero
  private let disposeBag = DisposeBag()
  private var swipeDeltaX: CGFloat = 0
  private var swipeDeltaY: CGFloat = 0
  private var keepFirstImageWindowSize: Bool = false

  @IBOutlet weak var imageStackView: NSStackView!
  @IBOutlet weak var firstImageView: BookImageView!
  @IBOutlet weak var secondImageView: BookImageView!
  @IBOutlet weak var leftPageNumberButton: NSButton!
  @IBOutlet weak var rightPageNumberButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    // TODO: Use NSStackView#setViews instead of use userInterfaceLayoutDirection for page order?
    self.imageStackView.userInterfaceLayoutDirection = .rightToLeft
    self.firstImageView.notificationName = firstImageViewMouseUpNotificationName
    self.secondImageView.notificationName = secondImageViewMouseUpNotificationName

    self.leftPageNumberButton.wantsLayer = true
    self.leftPageNumberButton.layer?.backgroundColor = CGColor(gray: 0.5, alpha: 0.4)
    self.leftPageNumberButton.layer?.cornerRadius = 10
    self.rightPageNumberButton.wantsLayer = true
    self.rightPageNumberButton.layer?.backgroundColor = CGColor(gray: 0.5, alpha: 0.6)
    self.rightPageNumberButton.layer?.cornerRadius = 10
    self.keepFirstImageWindowSize = UserDefaults.standard.bool(forKey: Self.keepFirstImageWindowSizeKey)

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
    self.showPageNumber
      .observe(on: MainScheduler.instance)
      .withUnretained(self)
      .subscribe(onNext: { owner, showPageNumber in
        owner.leftPageNumberButton.isHidden = !showPageNumber
        owner.rightPageNumberButton.isHidden = !showPageNumber
      })
      .disposed(by: self.disposeBag)
    self.showPageNumber.accept(UserDefaults.standard.bool(forKey: SpreadPageViewController.showPageNumberKey))
    self.viewStyle
      .observe(on: MainScheduler.instance)
      .subscribe(
        with: self,
        onNext: { owner, viewStyle in
          if viewStyle == .single {
            owner.setSinglePageView()
          } else {
            owner.setSpreadPageView()
          }
        }
      )
      .disposed(by: self.disposeBag)
  }

  override func viewWillDisappear() {
    super.viewWillDisappear()
    // Update book state
    if let document = self.representedObject as? BookDocument {
      try? document.storeViewerStatus(
        lastPageIndex: self.currentPageIndex.value,
        isRightToLeft: self.pageOrder.value == .rtl,
        shiftedSinglePage: self.shiftedSinglePage,
        manualViewHeight: self.manualViewHeight,
        viewStyle: self.viewStyle.value
      )
    }
  }

  func fetchImages(pageIndex: Int, document: BookDocument) -> Observable<LoadedImage> {
    return Observable.range(
      start: self.currentPageIndex.value,
      count: min(self.pageCount.value - self.currentPageIndex.value, 16)
    )
    .map { pageIndex in
      document.image(at: pageIndex)
    }
    .concat()
    .buffer(
      timeSpan: .never,
      count: pageIndex == 0 && !self.shiftedSinglePage ? 1 : 2,
      scheduler: MainScheduler.instance
    )
    .enumerated()
    .map { LoadedImage(preload: $0.index > 0, firstPageIndex: pageIndex, images: $0.element) }
  }

  override var representedObject: Any? {
    didSet {
      guard let document = representedObject as? BookDocument else { return }
      self.pageCount.accept(document.pageCount())
      self.shiftedSinglePage = document.shiftedSinglePage() ?? false
      if let lastPageIndex = document.lastPageIndex() {
        self.currentPageIndex.accept(lastPageIndex)
      }
      if let lastPageOrder = document.lastPageOrder() {
        self.pageOrder.accept(lastPageOrder)
      }
      self.pageOrder
        .distinctUntilChanged()
        .withUnretained(self)
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { owner, pageOrder in
          owner.imageStackView.userInterfaceLayoutDirection =
            pageOrder == PageOrder.rtl ? .rightToLeft : .leftToRight
          if !self.rightPageNumberButton.isHidden {
            let title = self.rightPageNumberButton.title
            self.rightPageNumberButton.title = self.leftPageNumberButton.title
            self.leftPageNumberButton.title = title
          }
        })
        .disposed(by: self.disposeBag)
      if let isLike = document.isLike() {
        self.like.accept(isLike)
      }
      if let viewStyle = document.viewStyle() {
        self.viewStyle.accept(viewStyle)
      }
      if let realm = try? threadLocalRealm(), let bookId = document.book?.id {
        if let book = realm.object(ofType: Book.self, forPrimaryKey: bookId) {
          Observable.from(object: book, properties: ["like"])
            .map { $0.like }
            .distinctUntilChanged()
            .subscribe(onNext: { like in
              self.like.accept(like)
            })
            .disposed(by: self.disposeBag)
        }
      }
      self.like
        .subscribe(onNext: { like in
          if let like {
            try? document.setLike(like)
          }
        })
        .disposed(by: self.disposeBag)
      self.currentPageIndex.flatMapLatest { (currentPageIndex) in
        self.fetchImages(pageIndex: currentPageIndex, document: document)
      }
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { (loadedImage) in
          //log.debug("image = \(loadedImage.images.count), prefetch = \(loadedImage.preload)")
          if loadedImage.preload || loadedImage.images.isEmpty {
            return
          }
          let images = loadedImage.images
          let firstImage: NSImage = images.first!  // TODO: It might be nil if all files are broken
          let secondImage: NSImage? = images.count >= 2 ? images.last : nil

          self.firstImageView.image = firstImage
          self.secondImageView.image = secondImage
          if self.currentPageIndex.value > 0 && self.viewStyle.value == .spread && secondImage != nil {
            self.setSpreadPageView()
          } else {
            self.setSinglePageView()
          }
          self.updateWindowContentSize()
        },
        onCompleted: {
          log.debug("onCompleted")
        }
      )
      .disposed(by: self.disposeBag)
    }
  }

  override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)
    coder.encode(self.currentPageIndex.value, forKey: "currentPageIndex")
  }

  override func restoreState(with coder: NSCoder) {
    super.restoreState(with: coder)
    let lastCurrentPageIndex = coder.decodeInteger(forKey: "currentPageIndex")
    self.currentPageIndex.accept(lastCurrentPageIndex)
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

  @IBAction func toggleShowPageNumber(_ sender: Any) {
    UserDefaults.standard.set(!self.showPageNumber.value, forKey: SpreadPageViewController.showPageNumberKey)
    self.showPageNumber.accept(!self.showPageNumber.value)
  }

  // increment page (two page increment in default)
  func forwardPage() {
    if self.viewStyle.value == .single {
      forwardSinglePage()
      return
    }
    let incremental =
      self.currentPageIndex.value == 0 && !self.shiftedSinglePage || self.viewStyle.value == .single ? 1 : 2
    if self.currentPageIndex.value + incremental < self.pageCount.value {
      self.currentPageIndex.accept(self.currentPageIndex.value + incremental)
    }
  }

  func forwardSinglePage() {
    if self.canForwardPage() {
      self.currentPageIndex.accept(self.currentPageIndex.value + 1)
      self.shiftedSinglePage = !self.shiftedSinglePage
    }
  }

  // decrement page (two page decrement in default)
  func backwardPage() {
    if self.viewStyle.value == .single {
      backwardSinglePage()
      return
    }
    let decremental = self.currentPageIndex.value == 1 ? 1 : 2
    if self.currentPageIndex.value - decremental >= 0 {
      self.currentPageIndex.accept(self.currentPageIndex.value - decremental)
    }
  }

  func backwardSinglePage() {
    if self.canBackwardPage() {
      self.currentPageIndex.accept(self.currentPageIndex.value - 1)
      self.shiftedSinglePage = !self.shiftedSinglePage
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

  func setBookViewStyle(_ bookViewStyle: BookViewStyle) {
    self.viewStyle.accept(bookViewStyle)
  }

  func resizedWindowByManual() {
    self.manualViewHeight = self.view.frame.size.height
  }

  private func setSpreadPageView() {
    self.firstImageView.imageAlignment = self.pageOrder.value == .rtl ? .alignLeft : .alignRight
    self.secondImageView.imageAlignment = self.pageOrder.value == .rtl ? .alignRight : .alignLeft
    self.secondImageView.isHidden = false
    if self.pageOrder.value == .rtl {
      if self.showPageNumber.value {
        self.rightPageNumberButton.title = String(self.currentPageIndex.value + 1)
        self.rightPageNumberButton.isHidden = false
        self.leftPageNumberButton.title = String(self.currentPageIndex.value + 2)
        self.leftPageNumberButton.isHidden = false
      }
    } else {
      if self.showPageNumber.value {
        self.leftPageNumberButton.title = String(self.currentPageIndex.value + 1)
        self.leftPageNumberButton.isHidden = false
        self.rightPageNumberButton.title = String(self.currentPageIndex.value + 2)
        self.rightPageNumberButton.isHidden = false
      }
    }
    self.updateWindowContentSize()
  }

  private func setSinglePageView() {
    self.firstImageView.imageAlignment = .alignCenter
    if self.showPageNumber.value {
      self.secondImageView.isHidden = true
      if self.pageOrder.value == .rtl {
        self.rightPageNumberButton.title = String(self.currentPageIndex.value + 1)
        self.rightPageNumberButton.isHidden = false
        self.leftPageNumberButton.title = String(self.currentPageIndex.value + 2)
        self.leftPageNumberButton.isHidden = true
      } else {
        self.leftPageNumberButton.title = String(self.currentPageIndex.value + 1)
        self.leftPageNumberButton.isHidden = false
        self.rightPageNumberButton.title = String(self.currentPageIndex.value + 2)
        self.rightPageNumberButton.isHidden = true
      }
    }
    self.updateWindowContentSize()
  }

  private func updateWindowContentSize() {
    guard let window = self.view.window else {
      log.error("window is nil")
      return
    }
    guard let firstImage = self.firstImageView.image else {
      log.debug("First Image is not yet loaded")
      return
    }

    let firstImageSize = self.imageSize(firstImage)
    let secondImage = self.secondImageView.isHidden ? nil : self.secondImageView.image
    let secondImageSize = secondImage != nil ? self.imageSize(secondImage!) : nil
    let contentWidth =
      max(firstImageSize.width, (secondImageSize?.width ?? 0)) * (secondImage != nil ? 2 : 1)
    let contentHeight = max(firstImageSize.height, (secondImageSize?.height ?? 0))
    window.contentAspectRatio = NSSize(width: contentWidth, height: contentHeight)
    // Set window size as screen size
    let resizeRatio: CGFloat
    if let manualViewHeight = self.manualViewHeight {
      resizeRatio = manualViewHeight / contentHeight
    } else if self.keepFirstImageWindowSize && self.contentSize != .zero {
      // Keep window height even if image is larger than prev image
      resizeRatio = self.contentSize.height < contentHeight ? self.contentSize.height / contentHeight : 1.0
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
}

extension SpreadPageViewController: NSMenuItemValidation {
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    guard let selector = menuItem.action else {
      return false
    }
    if selector == #selector(toggleShowPageNumber(_:)) {
      menuItem.state = UserDefaults.standard.bool(forKey: SpreadPageViewController.showPageNumberKey) ? .on : .off
    }
    return true
  }
}
