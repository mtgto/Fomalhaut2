// SPDX-License-Identifier: GPL-3.0-only

import Foundation
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
          if oldSchemaVersion < 1 {
            migration.enumerateObjects(ofType: Book.className()) { oldObject, newObject in
              let filePath = oldObject!["filePath"] as! String
              newObject!["name"] = URL(fileURLWithPath: filePath).lastPathComponent
              newObject!["like"] = false
              newObject!["pageCount"] = 0
              newObject!["manualViewHeight"] = RealmOptional<Double>()
            }
          }
        }
      })
    // start migration if need
    _ = try! Realm()
    self._state.onNext(.finish)
  }
}
