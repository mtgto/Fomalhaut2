import Cocoa
import RxCocoa
import RxRelay
import RxSwift

class BookViewController: NSSplitViewController {
  private var pageCount: Int = 0
  private var currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  private var leftImage: PublishSubject<NSImage> = PublishSubject<NSImage>()
  private var rightImage: PublishSubject<NSImage> = PublishSubject<NSImage>()
  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    if let viewController = self.splitViewItems[0].viewController as? PageViewController {
      viewController.imageView.imageAlignment = .alignRight
    }
    if let viewController = self.splitViewItems[1].viewController as? PageViewController {
      viewController.imageView.imageAlignment = .alignLeft
    }

    if let viewController = self.splitViewItems[0].viewController as? PageViewController {
      self.leftImage
        .asDriver(onErrorDriveWith: .empty())
        .drive(viewController.imageView.rx.image)
        .disposed(by: self.disposeBag)
    }

    if let viewController = self.splitViewItems[1].viewController as? PageViewController {
      self.rightImage
        .asDriver(onErrorDriveWith: .empty())
        .drive(viewController.imageView.rx.image)
        .disposed(by: self.disposeBag)
    }
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
      if let document = representedObject as? BookAccessible {
        self.pageCount = document.pageCount()

        self.currentPageIndex.asObservable().subscribe(onNext: { (pageIndex) in
          log.info("start to load at \(pageIndex)")
          pageLoadingOperationQueue.addOperation {
            document.image(at: pageIndex) { (result) in
              switch result {
              case .success(let image):
                self.leftImage.onNext(image)
                log.debug("success to load image at \(pageIndex)")
              case .failure(let error):
                log.info("fail to laod image at \(pageIndex): \(error)")
                self.leftImage.onError(error)
              }
            }
          }
          if pageIndex > 0 && pageIndex + 1 < self.pageCount {
            log.info("start to load at \(pageIndex + 1)")
            pageLoadingOperationQueue.addOperation {
              document.image(at: pageIndex + 1) { (result) in
                switch result {
                case .success(let image):
                  self.rightImage.onNext(image)
                  log.debug("success to load image at \(pageIndex + 1)")
                case .failure(let error):
                  log.info("fail to laod image at \(pageIndex + 1): \(error)")
                  self.rightImage.onError(error)
                }
              }
            }
          }
          // preload before increment page
          let preloadIndex = pageIndex > 0 && pageIndex + 1 < self.pageCount ? 2 : 1
          let preloadCount = 2
          (0..<preloadCount).forEach { (index) in
            if pageIndex + preloadIndex + index < self.pageCount {
              log.debug("start to preload at \(pageIndex + preloadIndex + index)")
              pageLoadingOperationQueue.addOperation {
                document.image(at: pageIndex + preloadIndex + index) { (_) in
                  // do nothing
                }
              }
            }
          }

          // hide right page if pageIndex == 0
          if pageIndex == 0 {
            self.splitViewItems[1].animator().isCollapsed = true
          } else {
            self.splitViewItems[1].animator().isCollapsed = false
          }
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

extension BookViewController {
  //  override func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
  //    log.info("XXXXX shouldAdjustSizeOfSubview")
  //    return view != self.splitViewItems[0].viewController
  //  }
}
