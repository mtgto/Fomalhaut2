import Cocoa

class BookViewController: NSSplitViewController {
  private var pageCount: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
      if let document = representedObject as? BookAccessible {
        self.pageCount = document.pageCount()
        document.image(at: 0) { (result) in
          switch result {
          case .success(let image):
            print("success")
            break
          case .failure(let error):
            print("\(error)")
          }
        }
      }
    }
  }
}
