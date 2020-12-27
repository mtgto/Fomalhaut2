CHANGELOG
====

## v0.5.2 (2020-12-27)

### Added

- Localizate web sharing
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
