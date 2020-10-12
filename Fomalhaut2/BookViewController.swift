import Cocoa
import RxCocoa
import RxRelay
import RxSwift

class BookViewController: NSSplitViewController {
  private var pageCount: Int = 0
  private var currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  private var image: PublishSubject<NSImage> = PublishSubject<NSImage>()
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
      self.image
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
          log.info("page index = \(pageIndex)")
          pageLoadingOperationQueue.addOperation {
            document.image(at: pageIndex) { (result) in
              switch result {
              case .success(let image):
                self.image.onNext(image)
                log.debug("success to load image at \(pageIndex)")
              case .failure(let error):
                log.info("fail to laod image at \(pageIndex): \(error)")
                self.image.onError(error)
              }
            }
          }
        }).disposed(by: self.disposeBag)
      }
    }
  }

  override func mouseUp(with event: NSEvent) {
    log.info("mouseUp")
    if self.currentPageIndex.value + 1 < self.pageCount {
      self.currentPageIndex.accept(self.currentPageIndex.value + 1)
    }
  }

  // increment page (two page increment)
  func incrementPage() {
    if self.currentPageIndex.value + 1 < self.pageCount {
      self.currentPageIndex.accept(self.currentPageIndex.value + 1)
    }
  }

  func decrementPage() {
    if self.currentPageIndex.value > 0 {
      self.currentPageIndex.accept(self.currentPageIndex.value - 1)
    }
  }
}
