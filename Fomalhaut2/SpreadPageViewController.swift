import Cocoa
import RxRelay
import RxSwift

class SpreadPageViewController: NSViewController {
  private var pageCount: Int = 0
  private var currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  private var firstImage: PublishSubject<NSImage> = PublishSubject<NSImage>()
  private var secondImage: PublishSubject<NSImage?> = PublishSubject<NSImage?>()
  private let disposeBag = DisposeBag()

  @IBOutlet weak var leftImageView: NSImageView!
  @IBOutlet weak var rightImageView: NSImageView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do view setup here.
    Observable.zip(self.firstImage, self.secondImage)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { images in
        let firstImage: NSImage = images.0
        let secondImage: NSImage? = images.1
        self.leftImageView.image = firstImage
        self.rightImageView.image = secondImage
        let contentWidth =
          max(firstImage.size.width, (secondImage?.size.width ?? 0)) * (secondImage != nil ? 2 : 1)
        let contentHeight = max(firstImage.size.height, (secondImage?.size.height ?? 0))
        // log.debug("Content size = \(contentWidth) x \(contentHeight)")
        self.view.window?.contentAspectRatio = NSSize(width: contentWidth, height: contentHeight)
      })
      .disposed(by: self.disposeBag)
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
      if let document = representedObject as? BookAccessible {
        self.pageCount = document.pageCount()

        self.currentPageIndex.asObservable().subscribe(onNext: { (pageIndex) in
          log.info("start to load at \(pageIndex)")
          // TODO: Try to obtain image from cache not to use OperationQueue
          document.image(at: pageIndex) { (result) in
            switch result {
            case .success(let image):
              self.firstImage.onNext(image)
              log.debug("success to load image at \(pageIndex)")
            case .failure(let error):
              log.info("fail to laod image at \(pageIndex): \(error)")
              self.firstImage.onError(error)
            }
          }
          if pageIndex > 0 && pageIndex + 1 < self.pageCount {
            log.info("start to load at \(pageIndex + 1)")
            document.image(at: pageIndex + 1) { (result) in
              switch result {
              case .success(let image):
                self.secondImage.onNext(image)
                log.debug("success to load image at \(pageIndex + 1)")
              case .failure(let error):
                log.info("fail to laod image at \(pageIndex + 1): \(error)")
                self.secondImage.onError(error)
              }
            }
          } else {
            self.secondImage.onNext(nil)
          }
          // preload before increment page
          let preloadIndex = pageIndex > 0 && pageIndex + 1 < self.pageCount ? 2 : 1
          let preloadCount = 2
          (0..<preloadCount).forEach { (index) in
            if pageIndex + preloadIndex + index < self.pageCount {
              log.debug("start to preload at \(pageIndex + preloadIndex + index)")
              document.image(at: pageIndex + preloadIndex + index) { (_) in
                // do nothing
              }
            }
          }

          // hide right page if pageIndex == 0
          //          if pageIndex == 0 {
          //            self.splitViewItems[1].animator().isCollapsed = true
          //          } else {
          //            self.splitViewItems[1].animator().isCollapsed = false
          //          }
        }).disposed(by: self.disposeBag)
      }
    }
  }

  override func mouseUp(with event: NSEvent) {
    log.info("mouseUp")
    self.incrementPage()
  }

  // increment page (two page increment)
  func incrementPage() {
    let incremental = self.currentPageIndex.value == 0 ? 1 : 2
    if self.currentPageIndex.value + incremental < self.pageCount {
      self.currentPageIndex.accept(self.currentPageIndex.value + incremental)
    }
  }

  func decrementPage() {
    let decremental = self.currentPageIndex.value == 1 ? 1 : 2
    if self.currentPageIndex.value - decremental >= 0 {
      self.currentPageIndex.accept(self.currentPageIndex.value - decremental)
    }
  }
}
