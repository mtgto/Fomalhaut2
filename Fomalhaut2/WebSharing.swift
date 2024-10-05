// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import NIO
import RealmSwift
import RxRealm
import RxRelay
import RxSwift
import Shared
import Swiftra
import ZIPFoundation

private let cacheControlKey = "Cache-Control"
private let noCache = "no-cache"
private let contentTypeJpeg = "image/jpeg"

class WebSharing: NSObject {
  static let shared = WebSharing()
  let remoteAddress = PublishRelay<String>()
  let started = BehaviorRelay<Bool>(value: false)
  private let server = App()
  private var collections: [Collection] = []
  private var books: [Book] = []
  private let cache = NSCache<NSString, CombineArchiver>()
  private let assetArchive: Archive!
  private let remoteIpAddress = PublishRelay<String>()
  private let lock = NSRecursiveLock()
  private let disposeBag = DisposeBag()
  private let notFound = Response(text: "Not Found", status: .notFound)
  private let internalServerError = Response(text: "Internal Server Error", status: .internalServerError)
  private let badRequest = Response(text: "Bad Request", status: .badRequest)
  private let jsonDecoder = JSONDecoder()

  enum WebServerError: Error {
    case badBookURL
    case notFoundAsset
  }

  override init() {
    let assetsURL = Bundle.main.url(forResource: "assets", withExtension: "zip")!
    self.assetArchive = try! Archive(url: assetsURL, accessMode: .read, pathEncoding: nil)
    self.cache.countLimit = 1
    super.init()
    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") {
      self.server.defaultHeaders = [
        ("Server", "Fomalhaut2/\(version)"),
        ("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'"),
      ]
    }
    self.server.addRoutes {
      futureGet("/") { req in
        self.recordAccess(req)
        return self.defaultHtml(req)
      }

      futureGet("/books/:id") { req in
        self.recordAccess(req)
        return self.defaultHtml(req)
      }

      futureGet("/collections/:id") { req in
        self.recordAccess(req)
        return self.defaultHtml(req)
      }

      futureGet("/filters/:id") { req in
        self.recordAccess(req)
        return self.defaultHtml(req)
      }

      futureGet("/assets/:filename") { req in
        self.recordAccess(req)
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
        self.recordAccess(req)
        return Response(json: self.collections, headers: [(cacheControlKey, noCache)]) ?? self.internalServerError
      }

      get("/api/v1/collections/:id") { req in
        self.recordAccess(req)
        guard let collection = self.collections.first(where: { $0.id == req.params("id") }) else {
          return self.notFound
        }
        return Response(json: collection, headers: [(cacheControlKey, noCache)]) ?? self.internalServerError
      }

      post("/api/v1/collections/:id") { req in
        struct Hoge: Decodable {
          let bookId: String
        }
        self.recordAccess(req)
        guard let body = req.data(), let json = try? self.jsonDecoder.decode(Hoge.self, from: body) else {
          return self.badRequest
        }
        guard let realm = try? threadLocalRealm() else {
          return self.internalServerError
        }
        guard let collection = realm.object(ofType: Collection.self, forPrimaryKey: req.params("id")) else {
          return self.notFound
        }
        guard let book = realm.object(ofType: Book.self, forPrimaryKey: json.bookId) else {
          return self.badRequest
        }
        do {
          try realm.write {
            collection.books.append(book)
          }
        } catch {
          return self.internalServerError
        }
        return Response(json: collection) ?? self.internalServerError
      }

      post("/api/v1/books/:id/like") { req in
        self.recordAccess(req)
        guard let realm = try? threadLocalRealm() else {
          return self.internalServerError
        }
        guard let book = realm.object(ofType: Book.self, forPrimaryKey: req.params("id")) else {
          return self.notFound
        }
        do {
          try realm.write {
            book.like = true
          }
        } catch {
          return self.internalServerError
        }
        return Response(json: book) ?? self.internalServerError
      }

      post("/api/v1/books/:id/dislike") { req in
        self.recordAccess(req)
        guard let realm = try? threadLocalRealm() else {
          return self.internalServerError
        }
        guard let book = realm.object(ofType: Book.self, forPrimaryKey: req.params("id")) else {
          return self.notFound
        }
        do {
          try realm.write {
            book.like = false
          }
        } catch {
          return self.internalServerError
        }
        return Response(json: book) ?? self.internalServerError
      }

      get("/api/v1/books") { req in
        self.recordAccess(req)
        return Response(json: self.books, headers: [(cacheControlKey, noCache)]) ?? self.internalServerError
      }

      get("/images/books/:id/thumbnail") { req in
        self.recordAccess(req)
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
        self.recordAccess(req)
        let promise = req.eventLoop.makePromise(of: Response.self)
        guard let book = self.books.first(where: { $0.id == req.params("id") }) else {
          promise.succeed(self.notFound)
          return promise.futureResult
        }
        let page = req.params("page").flatMap { Int($0) } ?? 0
        guard let archiver: Archiver = self.archiver(from: book) else {
          promise.succeed(self.internalServerError)
          return promise.futureResult
        }
        if page < 0 || archiver.pageCount() <= page {
          promise.succeed(self.notFound)
          return promise.futureResult
        }
        archiver.image(at: page) { (result) in
          switch result {
          case .success(let image):
            guard let data = image.resizedImageFixedAspectRatio(maxPixelsWide: 1024, maxPixelsHigh: 1024) else {
              log.warning("Fail to resize image with unknown reason")
              promise.succeed(self.internalServerError)
              break
            }
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

    self.remoteIpAddress
      .throttle(.seconds(30), scheduler: MainScheduler.asyncInstance)
      .observe(on: MainScheduler.asyncInstance)
      .subscribe { event in
        if let ipAddress = event.element {
          WebSharing.shared.remoteAddress.accept(ipAddress)
        }
      }
      .disposed(by: self.disposeBag)

    Schema.shared.state
      .skip { $0 != .finish }
      .withUnretained(self)
      .subscribe(onNext: { owner, _ in
        owner.setup()
      })
      .disposed(by: self.disposeBag)
  }

  func start(port: Int = 8080) throws {
    try self.server.start(port)
    log.info("WebServer started. port = \(port)")
    self.started.accept(true)
  }

  func stop(callback: ((Error?) -> Void)? = nil) {
    if self.started.value {
      self.server.stop { (error) in
        log.info("WebServer is stopped")
        self.started.accept(false)
        callback?(error)
      }
      log.info("WebServer is stopping.")
    }
  }

  private func setup() {
    let realm = try! threadLocalRealm()
    Observable.array(from: realm.objects(Collection.self).sorted(byKeyPath: "order"))
      .withUnretained(self)
      .subscribe(onNext: { owner, collections in
        owner.collections = collections.map { $0.freeze() }
      })
      .disposed(by: self.disposeBag)
    Observable.array(from: realm.objects(Book.self).sorted(byKeyPath: "createdAt"))
      .withUnretained(self)
      .subscribe(onNext: { owner, books in
        owner.books = books.map { $0.freeze() }
      })
      .disposed(by: self.disposeBag)
  }

  private func recordAccess(_ request: Request) {
    if let ipAddress = request.remoteAddress?.ipAddress {
      // ref. https://stackoverflow.com/a/54401485/6945346
      self.lock.lock()
      self.remoteIpAddress.accept(ipAddress)
      self.lock.unlock()
    }
  }

  private func defaultHtml(_ request: Request) -> EventLoopFuture<Response> {
    return self.loadAsset("index.html", request: request)
      .map { Response(data: $0, contentType: ContentType.textHtml.withCharset()) }
      .recover { _ in
        Response(text: "Error", status: .internalServerError, contentType: ContentType.textPlain.withCharset())
      }
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
        entry, bufferSize: Int(entry.uncompressedSize), skipCRC32: true, progress: nil
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

  private func archiver(from book: Book) -> Archiver? {
    if let archiver = self.cache.object(forKey: book.id as NSString) {
      return archiver
    }
    var bookmarkDataIsStale: Bool = false
    guard let url = try? book.resolveURL(bookmarkDataIsStale: &bookmarkDataIsStale) else {
      log.error("Error while resolve URL from a book")
      return nil
    }
    _ = url.startAccessingSecurityScopedResource()
    do {
      let typeName = try NSDocumentController.shared.typeForContents(of: url)
      if let archiver = CombineArchiver(from: url, ofType: typeName) {
        self.cache.setObject(archiver, forKey: book.id as NSString)
        return archiver
      }
    } catch {
      log.error("Error while getting type from file: \(error)")
    }
    return nil
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
