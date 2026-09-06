# MacEase

[简体中文](README.zh-CN.md)

MacEase adds small, native conveniences to macOS and stays available from the menu bar.

## Features

- Create an empty file from the Finder context menu.
- Create a folder from the Finder context menu.
- Rename a newly created item in place in Finder.
- Keep MacEase in the menu bar without occupying the Dock after its window closes.
- Set natural or reversed scrolling independently for the trackpad and mouse wheel.
- Open or switch to pinned Dock apps with Command + number shortcuts.
- Use MacEase in English or Simplified Chinese according to the macOS language setting.
- Navigate settings by feature in a resizable window that remembers the last visited page.

## Requirements

- macOS 13 Ventura or later
- Apple Silicon Mac

## Install

1. Download `MacEase-vX.Y.Z-arm64.dmg` from the [latest release](https://github.com/lkpsg/MacEase/releases/latest).
2. Open the DMG and drag `MacEase.app` to `Applications`.
3. Control-click MacEase and choose **Open** on the first launch.
4. In MacEase’s **Permissions & Extensions** page, enable the Finder extension and grant Accessibility access for in-place renaming and scroll direction control.

The downloadable build is ad-hoc signed and is not Apple-notarized yet.

## Settings

Select Finder, Scroll direction or Dock app shortcuts in the sidebar to configure that feature. Help is collapsed by default; missing permissions and shortcut conflicts appear only when relevant. **Permissions & Extensions** centralizes system access, and **About MacEase** shows version information.

The window remembers its last page, size and position. The menu bar provides quick toggles for scrolling and Dock shortcuts, plus Open Settings and Quit.

## Dock app shortcuts

Enable **Dock App Shortcuts** in settings or the menu bar. `⌘1`–`⌘9` open or switch to the first nine pinned Dock apps, and `⌘0` opens the tenth. Numbering starts after Finder by default; enable **Count Finder as the first app** to include it. Settings show the current app assigned to each shortcut.

Assignments update automatically when pinned apps are moved, added or removed. Recent apps, folders and spacers do not count. This feature needs no Accessibility access and is off by default. When enabled, assigned shortcuts take priority over the current app’s Command + number actions. Unassigned numbers remain available; turning the feature off releases all shortcuts.

If a shortcut is unavailable, quit Snap or another utility using it. MacEase retries automatically.

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

To run the system hotkey integration tests, use a logged-in macOS desktop and quit MacEase, Snap and other utilities that reserve these shortcuts:

```bash
./scripts/test-dock-shortcuts.sh
# Also exercise real keyboard event delivery; requires event-posting permission:
./scripts/test-dock-shortcuts.sh --post-key-events
```

To build a distributable DMG locally:

```bash
./scripts/build-release.sh
```

## Versioning

MacEase follows [Semantic Versioning](https://semver.org/), with the current version and build number stored in `Config/Version.xcconfig`.

```bash
./scripts/set-version.sh 0.3.1
./scripts/check-version.sh
```

Tags must use `vMAJOR.MINOR.PATCH`; pushing a matching tag builds and publishes a GitHub Release automatically.

## License

[MIT](LICENSE)
