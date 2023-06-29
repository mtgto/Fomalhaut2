// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
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
  // 1: v0.3.0 - v0.3.1
  // 2: v0.3.2 - v0.9.1
  // 3: v0.9.2 - v1.4.3
  // 4: v1.5.0 -
  static let schemaVersion: UInt64 = 4
  static let shared = Schema()
  // only one event is streamed after anyone subscribe
  let state: Observable<SchemaMigrationState>
  private let _state: PublishSubject<SchemaMigrationState>

  init() {
    self._state = PublishSubject<SchemaMigrationState>()
    self.state = self._state.share(replay: 1)
  }

  func migrate() throws {
    var needReorderCollection: Bool = false
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
              newObject!["manualViewHeight"] = nil
            }
            if oldSchemaVersion < 2 {
              let bookmarkData = oldObject!["bookmark"] as! Data
              do {
                var bookarmDataIsStale = false
                let url = try URL(
                  resolvingBookmarkData: bookmarkData, options: [.withoutMounting],
                  bookmarkDataIsStale: &bookarmDataIsStale)
                let newBookmarkData = try url.bookmarkData(options: [
                  .withSecurityScope, .securityScopeAllowOnlyReadAccess,
                ])
                let newUrl = try URL(
                  resolvingBookmarkData: newBookmarkData,
                  options: [.withoutMounting, .withSecurityScope],
                  bookmarkDataIsStale: &bookarmDataIsStale)
                newObject!["bookmark"] = newBookmarkData
                newObject!["filePath"] = newUrl.path
              } catch {
                log.warning("Error occurs while regenerating bookmark: \(error)")
                migration.delete(newObject!)
              }
            }
          }
          if oldSchemaVersion < 3 {
            needReorderCollection = true
            migration.enumerateObjects(ofType: Collection.className()) { oldObject, newObject in
              newObject!["order"] = 0
            }
          }
          if oldSchemaVersion < 4 {
            migration.renameProperty(onType: Book.className(), from: "shiftedSignlePage", to: "shiftedSinglePage")
            migration.enumerateObjects(ofType: Book.className()) { oldObject, newObject in
              newObject!["viewStyle"] = 0
            }
          }
        }
      })
    // start migration if need.
    // NOTE: If database version is newer than schemaVersion, an exception is raised.
    // ex. "Provided schema version 1 is less than last set version 2."
    let realm = try threadLocalRealm()
    if needReorderCollection {
      let collections = realm.objects(Collection.self).sorted(byKeyPath: "createdAt")
      try realm.write {
        for (i, collection) in collections.enumerated() {
          collection.order = i
        }
      }
    }
    self._state.onNext(.finish)
  }
}
