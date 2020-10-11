import Cocoa
import RxRelay
import RxSwift

class BookViewController: NSSplitViewController {
  private var pageCount: Int = 0
  private var currentPageIndex: BehaviorRelay<Int> = BehaviorRelay(value: 0)
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
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
      if let document = representedObject as? BookAccessible {
        self.pageCount = document.pageCount()

        self.currentPageIndex.asObservable().subscribe(onNext: { (pageIndex) in
          log.info("page index = \(pageIndex)")
          document.image(at: pageIndex) { (result) in
            switch result {
            case .success(let image):
              if let viewController = self.splitViewItems[0].viewController as? PageViewController {
                viewController.imageView.image = image
                self.view.window?.contentAspectRatio = NSSize(
                  width: image.size.width, height: image.size.height)
              }
              print("success")
              break
            case .failure(let error):
              print("\(error)")
            }
          }
        }).disposed(by: self.disposeBag)
      }
    }
  }

  override func mouseUp(with event: NSEvent) {
    log.info("mouseUp")
    self.currentPageIndex.accept(self.currentPageIndex.value + 1)
  }
}
