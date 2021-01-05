// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import NIO
import RealmSwift
import RxRealm
import RxRelay
import RxSwift
import Swiftra
import ZIPFoundation

private let cacheControlKey = "Cache-Control"
private let noCache = "no-cache"
private let contentTypeJpeg = "image/jpeg"

class WebSharing: NSObject {
  private let server = App()
  //private let server: HttpServer = HttpServer()
  private(set) var started: Bool = false
  private var collections: [Collection] = []
  private var books: [Book] = []
  private let cache = NSCache<NSString, NSDocument>()
  private let assetArchive: Archive
  private let disposeBag = DisposeBag()
  private let notFound = Response(text: "Not Found", status: .notFound)
  private let internalServerError = Response(text: "Internal Server Error", status: .internalServerError)

  enum WebServerError: Error {
    case badBookURL
    case notFoundAsset
  }

  override init() {
    let assetsURL = Bundle.main.url(forResource: "assets", withExtension: "zip")!
    self.assetArchive = Archive(url: assetsURL, accessMode: .read)!
    self.cache.countLimit = 1
    super.init()
    self.server.addRoutes {
      futureGet("/") { req in
        self.defaultHtml(req)
      }

      futureGet("/books/:id") { req in
        self.defaultHtml(req)
      }

      futureGet("/collections/:id") { req in
        self.defaultHtml(req)
      }

      futureGet("/assets/:filename") { req in
        guard let filename = req.params("filename") else {
          return req.eventLoop.makeSucceededFuture(self.notFound)
        }
        let contentType: String
        if filename.hasSuffix(".js") {
          contentType = "text/javascript; charset=utf-8"
        } else if filename.hasSuffix(".map") {
          contentType = ContentType.applicationJson.withCharset()
        } else if filename.hasSuffix(".ico") {
          contentType = "image/x-ico"
        } else {
          contentType = ContentType.applicationOctetStream.rawValue
        }
        return self.loadAsset(filename, request: req)
          .map { Response(data: $0, contentType: contentType) }
      }

      get("/api/v1/collections") { req in
        Response(json: self.collections, headers: [(cacheControlKey, noCache)]) ?? self.internalServerError
      }

      get("/api/v1/collections/:id") { req in
        guard let collection = self.collections.first(where: { $0.id == req.params("id") }) else {
          return self.notFound
        }
        return Response(json: collection, headers: [(cacheControlKey, noCache)]) ?? self.internalServerError
      }

      get("/api/v1/books") { req in
        Response(json: self.books, headers: [(cacheControlKey, noCache)]) ?? self.internalServerError
      }

      get("/images/books/:id/thumbnail") { req in
        guard let book = self.books.first(where: { $0.id == req.params("id") }) else {
          return self.notFound
        }
        if let thumbnail = book.thumbnailData {
          return Response(
            data: thumbnail, contentType: contentTypeJpeg, headers: [(cacheControlKey, "private, max-age=1440")])
        } else {
          let url = Bundle.main.url(forResource: "defaultThumbnail", withExtension: "jpg")!
          let data = try! Data(contentsOf: url)
          return Response(data: data, contentType: contentTypeJpeg, headers: [(cacheControlKey, "private, max-age=60")])
        }
      }

      futureGet("/images/books/:id/pages/:page") { req in
        let promise = req.eventLoop.makePromise(of: Response.self)
        guard let book = self.books.first(where: { $0.id == req.params("id") }) else {
          promise.succeed(self.notFound)
          return promise.futureResult
        }
        let page = req.params("page").flatMap { Int($0) } ?? 0
        guard let document: BookAccessible = try? self.document(from: book) else {
          promise.succeed(self.internalServerError)
          return promise.futureResult
        }
        if page < 0 || document.pageCount() <= page {
          promise.succeed(self.notFound)
          return promise.futureResult
        }
        document.image(at: page) { (result) in
          switch result {
          case .success(let image):
            let data = image.resizedImageFixedAspectRatio(maxPixelsWide: 1024, maxPixelsHigh: 1024)!
            promise.succeed(
              Response(data: data, contentType: contentTypeJpeg, headers: [(cacheControlKey, "private, max-age=1440")]))
          case .failure(let error):
            log.warning("Fail to resize image: \(error)")
            promise.succeed(self.internalServerError)
          }
        }
        return promise.futureResult
      }
    }

    Schema.shared.state
      .skipWhile { $0 != .finish }
      .subscribe(onNext: { [unowned self] _ in
        self.setup()
      })
      .disposed(by: self.disposeBag)
  }

  func start(port: Int = 8080) throws {
    try self.server.start(port)
    log.info("WebServer started. port = \(port)")
    self.started = true
  }

  func stop(callback: ((Error?) -> Void)? = nil) {
    if self.started {
      self.server.stop { (error) in
        log.info("WebServer is stopped")
        self.started = false
        callback?(error)
      }
      log.info("WebServer is stopping.")
    }
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
  }

  private func defaultHtml(_ request: Request) -> EventLoopFuture<Response> {
    return self.loadAsset("index.html", request: request)
      .map { Response(data: $0, contentType: ContentType.textHtml.withCharset()) }
      .recover { _ in Response(text: "Error", status: .notFound, contentType: ContentType.textPlain.withCharset()) }
  }

  private func loadAsset(_ filename: String, request: Request) -> EventLoopFuture<Data> {
    let promise = request.eventLoop.makePromise(of: Data.self)
    guard let entry = self.assetArchive[filename] else {
      promise.fail(WebServerError.notFoundAsset)
      return promise.futureResult
    }
    var data: Data = Data()
    do {
      _ = try self.assetArchive.extract(
        entry, bufferSize: UInt32(entry.uncompressedSize), skipCRC32: true, progress: nil
      ) { (html) in
        data.append(html)
      }
      promise.succeed(data)
    } catch {
      log.warning("Error while loading asset \(filename): \(error)")
      promise.fail(error)
    }
    return promise.futureResult
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
    if ["zip", "cbz"].contains(url.pathExtension.lowercased()) {
      document =
        try NSDocumentController.shared.makeDocument(withContentsOf: url, ofType: ZipDocument.UTIs.first!)
        as! BookAccessible
    } else if ["rar", "cbr"].contains(url.pathExtension.lowercased()) {
      document = try RarDocument(contentsOf: url, ofType: "RAR")
    } else {
      document = try PdfDocument(contentsOf: url, ofType: "PDF")
    }
    self.cache.setObject(document, forKey: book.id as NSString)
    return document
  }
}

// MARK: - NSCacheDelegate
extension WebSharing: NSCacheDelegate {
  func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    if let document = obj as? NSDocument {
      document.fileURL?.stopAccessingSecurityScopedResource()
    }
  }
}
