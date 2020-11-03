// SPDX-License-Identifier: GPL-3.0-only

import RealmSwift
import RxRelay
import RxSwift

class Schema {
  // 0: v0.1.0 - v0.2.0
  // 1: v0.3.0 -
  static let schemaVersion: UInt64 = 0
  static let shared = Schema()
  // only one event is streamed after anyone subscribe
  let migrated: Single<Void>
  private let _migrated: PublishSubject<Void>
  private(set) var needMigrate: Bool

  init() {
    self._migrated = PublishSubject()
    self.migrated = self._migrated.share(replay: 1).asSingle()
    self.needMigrate = Schema.schemaVersion > Realm.Configuration.defaultConfiguration.schemaVersion
  }

  func migrate() {
    if Schema.schemaVersion == Realm.Configuration.defaultConfiguration.schemaVersion {
      self._migrated.onNext(())
      self._migrated.onCompleted()
      return
    }
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
      schemaVersion: Schema.schemaVersion,
      migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < Schema.schemaVersion {
          // The enumerateObjects(ofType:_:) method iterates
          // over every Person object stored in the Realm file
          migration.enumerateObjects(ofType: Book.className()) { oldObject, newObject in
            // combine name fields into a single field
            let firstName = oldObject!["firstName"] as! String
            let lastName = oldObject!["lastName"] as! String
            newObject!["fullName"] = "\(firstName) \(lastName)"
          }
        }
        self._migrated.onNext(())
        self._migrated.onCompleted()
      })
  }
}
