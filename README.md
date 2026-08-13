# MacEase

[简体中文](README.zh-CN.md)

MacEase adds small, native conveniences to macOS and stays available from the menu bar.

## Features

- Create an empty file from the Finder context menu.
- Create a folder from the Finder context menu.
- Rename a newly created item in place in Finder.
- Keep MacEase in the menu bar without occupying the Dock after its window closes.
- Use MacEase in English or Simplified Chinese according to the macOS language setting.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon Mac

## Install

1. Download `MacEase-vX.Y.Z-arm64.dmg` from the [latest release](https://github.com/lkpsg/MacEase/releases/latest).
2. Open the DMG and drag `MacEase.app` to `Applications`.
3. Control-click MacEase and choose **Open** on the first launch.
4. In MacEase, enable the Finder extension and grant Accessibility access for automatic in-place renaming.

The downloadable build is ad-hoc signed and is not Apple-notarized yet.

## Build from source

Install Xcode Command Line Tools and XcodeGen, then run:

```bash
xcode-select --install
brew install xcodegen
git clone https://github.com/lkpsg/MacEase.git
cd MacEase
./scripts/verify.sh
./scripts/install-debug-app.sh
```

To build a distributable DMG locally:

```bash
./scripts/build-release.sh
```

## Versioning

MacEase follows [Semantic Versioning](https://semver.org/), with the current version and build number stored in `Config/Version.xcconfig`.

```bash
./scripts/set-version.sh 0.2.0
./scripts/check-version.sh
```

Tags must use `vMAJOR.MINOR.PATCH`; pushing a matching tag builds and publishes a GitHub Release automatically.

## License

[MIT](LICENSE)
