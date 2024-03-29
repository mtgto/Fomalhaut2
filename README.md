# Fomalhaut2

[![swift-format](https://github.com/mtgto/Fomalhaut2/workflows/swift-format/badge.svg)](https://github.com/mtgto/Fomalhaut2/actions?query=workflow%3Aswift-format)
[![web](https://github.com/mtgto/Fomalhaut2/workflows/web/badge.svg)](https://github.com/mtgto/Fomalhaut2/actions?query=workflow%3Aweb)

A comic viewer for macOS.

- A native macOS GUI application
- Collect your own comics (zip/cbz, rar/cbr, 7z/cb7, PDF)
- See your own comics via web browser

## Install

You can choose Mac App Store or download from github release page.

### 1. Mac App Store (Recommended)

[![Download on the Mac App Store](https://github.com/mtgto/Fomalhaut2/blob/gh-pages/download-on-the-mac-app-store.svg)](https://apps.apple.com/us/app/fomalhaut2/id1546526588?mt=12)

### 2. Manual Download

NOTE: manual download app does not have a feature `Check for update`.

1. Download .dmg file from [Release page](https://github.com/mtgto/Fomalhaut2/releases).
2. Copy `Fomalhaut2.app` to `/Applications` (or you want to).

## Uninstall

1. Move `Fomalhaut2.app` to Trash.
2. Delete `~/Library/Containers/net.mtgto.Fomalhaut2`.

## Screenshots

NOTE: This sample comic is under Public Domain. You can view via https://digitalcomicmuseum.com/index.php?dlid=11721

![Collection screenshot](https://github.com/mtgto/Fomalhaut2/blob/gh-pages/screenshot1.png)

![Viewer screenshot](https://github.com/mtgto/Fomalhaut2/blob/gh-pages/screenshot2.png)

## Development

Install node.js and pnpm.

```console
cd web
pnpm install
pnpm build
```

## System requirements

- macOS 11.5+

## Roadmap

- [x] Web server
  - [x] Access comics via web browser (PC / smartphone)
- [ ] Support more file types
  - [x] zip/cbz
  - [x] PDF
  - [x] rar/cbr
  - [x] 7z/cb7
- [x] QuickLook Thumbnail Extension

## Contributing

Use [swift-format](https://github.com/apple/swift-format).

## Authors

mtgto

## License

GPL 3.0
