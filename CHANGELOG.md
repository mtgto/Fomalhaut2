CHANGELOG
====

## v0.3.2 (2020-XX-XX)

### Added

- Add popup button to switch order of collection view

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
