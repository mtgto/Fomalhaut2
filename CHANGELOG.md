CHANGELOG
====

## v0.9.2 (2021-03-14)

### Added

- Add new feature to reorder collections by drag & drop

### Changed

- Add missing localized message
- Update web packages

## v0.9.1 (2021-03-07)

### Added

- Add a footer button to add a new collection
- Add comic files under drag'n'dropped folder

### Changed

- Fix to ignore dropped files already added
- Add missing localized messages
- Update Unrar to v0.3.1
- Update ZIPFoundation to v0.9.12

## v0.9.0 (2021-02-28)

### Added

- Add QuickLook Preview Extension for zip/cbz/rar/cbr files
- Add new sort order `by name` for collection view
- Restore last selected sort order of collection view

### Changed

- Center two spread images to avoid margin
- Sort entries of RAR archive

## v0.8.2 (2021-02-21)

### Added

- Add a preference window

### Changed

- Use embedded framework (for QuickLook feature)
- Update RxSwift to 6.1.0
- Update Swiftra to 0.4.0

## v0.8.1 (2021-02-14)

### Added

- Show tiny access log for web sharing
- Restore selected collection tab when app restart

### Changed

- Disable unsupported files drop to collection
- Set `public.data` to exported file type of `cbz` and `cbr`
- Update realm-core to 10.5.2
- Update web packages

## v0.8.0 (2021-02-07)

### Added

- Enable trackpad swipe page direction (#2)
- Enable shift-click to go backwise page

### Changed

- Fix white margin top and bottom in full screen (#3)
- Update Unrar to 0.3.0
- Update web packages

## v0.7.2 (2021-01-31)

### Changed

- Fix the comic file couldn't be droped in an image view of item of CollectionView
- Update to RxSwift 6 and RxRealm 5

## v0.7.1 (2021-01-24)

### Added

- Add "Toggle Like" button to toolbar of book window
- Add pagination to a collection page and a filter page on web

### Changed

- Add `Archiver` class to avoid using NSDocument for web sharing
- Update web packages

## v0.7.0 (2021-01-17)

### Added

- Add `Like` to books (app/web)

### Changed

- Add missing localization to web libraries
- Add GitHub Action to run swift-lint, eslint and tsc type checking

## v0.6.0 (2021-01-10)

### Added

- Support RAR/CBR file format

### Changed

- Set thumbnail data if image resolve from cache

## v0.5.3 (2021-01-03)

### Added

- Renew collection view of web sharing (shrink padding, etc.)
- Add default thumbnail image for no thumbnail book

### Changed

- Backward page when user click previous page
- Set book title to tooltips of filename label
- Add cache header to http response

## v0.5.2 (2020-12-27)

### Added

- Localize web sharing
- Show reload snackbar on api call is failure
- Add shortcut (Cmd-K) to open web sharing view

### Changed

- Reduce size of thumbnail of books (178x272 px => 133.5x204 px (75%))
- Fix unable to open cbz file in web sharing
- Update [Swiftra](https://github.com/mtgto/Swiftra) to v0.2.1
- Fix app crashs with wrong url access
- Fix `Credits.rtf` lacks Fomalhaut2 information

## v0.5.1 (2020-12-20)

### Added

- Use [Swiftra](https://github.com/mtgto/Swiftra) to stabilize web sharing
- Add "GO TO PAGE TOP" button to bottom of the book web page

### Changed

- Add margin between images of web book
- Show number of books in title of web books

## v0.5.0 (2020-12-13)

### Added

- Web Sharing (experimental)
  - Add `com.apple.security.network.server` (Network server feature) to App Sandbox entitlements

### Changed

- Update page count of book on closing a book window

## v0.4.1 (2020-12-06)

### Added

- Enable multiple selection
- Add "Go first" button to toolbar

### Changed

- Enable to drag from file list to drop collection list
- Set limitation to preload pages
- Delete labels of segmented control in toolbar
- Set inset to collection view

## v0.4.0 (2020-11-29)

### Added

- Book collections

### Changed

- Hide toolbar in fullscreen mode
- Fix wrong window position in fullscreen mode
- Add copyright header to swift files
- Add install/uninstall descriptions

## v0.3.3 (2020-11-22)

### Added

- Add Japanese translation
- Set toolbar icon to control page order
- Show alert when app fails to open a book
- Show alert when app fails database migration

### Changed

- Fix app crash when user click file header of list view

## v0.3.2 (2020-11-15)

### Added

- Add popup button to switch order of collection view
- Universal Binary for Apple Silicon (Not tested)

### Changed

- Fix wrong restoring Security-Scoped bookmark
- Fix cbz file support

## v0.3.1 (2020-11-08)

### Changed

- Fix to generate Security-Scoped bookmark on creating new comic book data

## v0.3.0 (2020-11-08)

### Added

- Restore page order and half-page-shifted state after comic is reopened
- Restore comic window position after comic is reopened
- Add database schema migration dialog
- Add `Go First` menu item to `Control` menu
- Add arrow up/down, j/k to shortcuts to move page
- Add `View As` menu to `View` menu

### Changed

- Set white to background color of comic view
- Fix thumbnail size changes whether display is retina or not
- Use NSStackView for main view instead of NSSplitView
- Bugfix can't open cbz files
- Create [Security-Scoped bookmark](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInDepth/AppSandboxInDepth.html#//apple_ref/doc/uid/TP40011183-CH3-SW1) for comic files. Old data might be deleted if app can not migrate.

## v0.2.0 (2020-11-01)

### Added

- Support PDF type
- Support search field
- Sort items by clicking list headers

### Changed

- Fix wrong book window top position
- Fix to keep window height after page is changed

## v0.1.0 (2020-10-25)

- First release
