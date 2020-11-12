// SPDX-License-Identifier: GPL-3.0-only

import Cocoa
import RealmSwift
import RxRelay
import RxSwift

enum SchemaMigrationState {
  case start, finish
}

class Schema {
  // 0: v0.1.0 - v0.2.0
  // 1: v0.3.0 -
  static let schemaVersion: UInt64 = 1
  static let shared = Schema()
  // only one event is streamed after anyone subscribe
  let state: Observable<SchemaMigrationState>
  private let _state: PublishSubject<SchemaMigrationState>

  init() {
    self._state = PublishSubject<SchemaMigrationState>()
    self.state = self._state.share(replay: 1)
  }

  func migrate() {
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
      schemaVersion: Schema.schemaVersion,
      migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < Schema.schemaVersion {
          self._state.onNext(.start)
          migration.enumerateObjects(ofType: Book.className()) { oldObject, newObject in
            if oldSchemaVersion < 1 {
              let filePath = oldObject!["filePath"] as! String
              newObject!["name"] = URL(fileURLWithPath: filePath).lastPathComponent
              if let thumbnail = oldObject!["thumbnailData"] as? Data,
                let image = NSImage(data: thumbnail),
                let regeneratedThumbnail = image.resizedImageFixedAspectRatio(
                  maxPixelsWide: BookDocument.thumbnailMaxWidth,
                  maxPixelsHigh: BookDocument.thumbnailMaxHeight)
              {
                newObject!["thumbnailData"] = regeneratedThumbnail
              }
              newObject!["like"] = false
              newObject!["pageCount"] = 0
              newObject!["manualViewHeight"] = RealmOptional<Double>()
              // Update bookmark because v0.2.0 or prior version did not create bookmark for sandbox
              let bookmarkData = oldObject!["bookmark"] as! Data
              do {
                var bookarmDataIsStale = false
                let url = try URL(
                  resolvingBookmarkData: bookmarkData, options: [.withoutMounting, .withoutUI],
                  bookmarkDataIsStale: &bookarmDataIsStale)
                let newBookmarkData = try url.bookmarkData(options: [
                  .withSecurityScope, .securityScopeAllowOnlyReadAccess,
                ])
                let newUrl = try URL(
                  resolvingBookmarkData: newBookmarkData, options: [.withoutMounting, .withoutUI],
                  bookmarkDataIsStale: &bookarmDataIsStale)
                newObject!["bookmark"] = newBookmarkData
                newObject!["filePath"] = newUrl.path
              } catch {
                log.warning("Error occurs while regenerating bookmark from \(filePath): \(error)")
                migration.delete(newObject!)
              }
            }
          }
        }
      })
    // start migration if need
    _ = try! Realm()
    self._state.onNext(.finish)
  }
}
