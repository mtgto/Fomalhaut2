// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRealm
import RxRelay
import RxSwift
import Swifter

class WebServer: NSObject {
  private let server: HttpServer = HttpServer()
  private(set) var started: Bool = false
  private var collections: [Collection] = []
  private var books: [Book] = []
  private let cache = NSCache<NSString, NSDocument>()
  private let disposeBag = DisposeBag()

  enum WebServerError: Error {
    case badBookURL
  }

  override init() {
    super.init()
    self.cache.countLimit = 1
    Schema.shared.state
      .skipWhile { $0 != .finish }
      .subscribe(onNext: { [unowned self] _ in
        self.setup()
      })
      .disposed(by: self.disposeBag)
  }

  func start(port: in_port_t = 8080) throws {
    try self.server.start(port, forceIPv4: true, priority: .default)
    log.info("WebServer started. port = \(port)")
    self.started = true
  }

  func stop() {
    self.server.stop()
    log.info("WebServer stopped.")
    self.started = false
  }

  private func setup() {
    let realm = try! Realm()
    Observable.array(from: realm.objects(Collection.self).sorted(byKeyPath: "createdAt", ascending: true))
      .subscribe(onNext: { [unowned self] collections in
        self.collections = collections.map { $0.freeze() }
      })
      .disposed(by: self.disposeBag)
    Observable.array(from: realm.objects(Book.self).sorted(byKeyPath: "createdAt"))
      .subscribe(onNext: { [unowned self] books in
        self.books = books.map { $0.freeze() }
      })
      .disposed(by: self.disposeBag)
    self.server["/api/v1/collections"] = { request in
      .ok(.json(self.collections.map { self.convert(collection: $0) }))
    }
    self.server["/api/v1/books"] = { request in
      .ok(.json(self.books.map { self.convert(book: $0) }))
    }
    self.server["assets/books/:id/thumbnail"] = { request in
      guard let book = self.books.first(where: { $0.id == request.params[":id"] }) else {
        return .notFound
      }
      if let thumbnail = book.thumbnailData {
        return .ok(.data(thumbnail, contentType: "image/jpeg"))
      } else {
        // TODO: return default image
        return .notFound
      }
    }
    self.server["assets/books/:id/pages/:page"] = { request in
      guard let book = self.books.first(where: { $0.id == request.params[":id"] }) else {
        return .notFound
      }
      let page = Int(request.params[":page"]!)!
      guard let document: BookAccessible = try? self.document(from: book) else {
        return .internalServerError
      }
      let semaphore = DispatchSemaphore(value: 0)
      var data: Data = Data()
      if page < 0 || document.pageCount() <= page {
        return .badRequest(nil)
      }
      document.image(at: page) { (result) in
        switch result {
        case .success(let image):
          data = image.resizedImageFixedAspectRatio(maxPixelsWide: 1024, maxPixelsHigh: 1024)!
        case .failure(_):
          break
        }
        semaphore.signal()
      }
      semaphore.wait()
      if data.count > 0 {
        return .ok(.data(data, contentType: "image/jpeg"))
      } else {
        return .notFound
      }
    }
  }

  private func document(from book: Book) throws -> BookAccessible {
    if let document = self.cache.object(forKey: book.id as NSString) as? BookAccessible {
      return document
    }
    var bookmarkDataIsStale: Bool = false
    guard let url = try? book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale) else {
      log.error("Error while resolve URL from a book")
      throw WebServerError.badBookURL
    }
    _ = url.startAccessingSecurityScopedResource()
    let document: BookAccessible
    if url.pathExtension.lowercased() == "zip" {
      document =
        try NSDocumentController.shared.makeDocument(withContentsOf: url, ofType: ZipDocument.UTIs.first!)
        as! BookAccessible
    } else {
      document = try PdfDocument(contentsOf: url, ofType: "PDF")
    }
    self.cache.setObject(document, forKey: book.id as NSString)
    return document
  }

  private func convert(book: Book) -> Any {
    return [
      "id": book.id,
      "name": book.name,
      "readCount": book.readCount,
      "pageCount": book.pageCount,
      "like": book.like
    ]
  }

  private func convert(collection: Collection) -> Any {
    return [
      "id": collection.id,
      "name": collection.name
    ]
  }
}

// MARK: - NSCacheDelegate
extension WebServer: NSCacheDelegate {
  func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    if let document = obj as? NSDocument {
      document.fileURL?.stopAccessingSecurityScopedResource()
    }
  }
}
