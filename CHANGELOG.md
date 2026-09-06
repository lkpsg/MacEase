# Changelog

All notable changes to MacEase are documented here. The project follows [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2026-09-06

- Added Command + 1–9 and 0 shortcuts to launch or activate the first ten pinned Dock apps.
- Added optional Finder numbering, automatic Dock order updates, and a settings list of app assignments.
- Added settings and menu bar toggles, shortcut conflict reporting, and automatic retry when conflicts clear.
- Added Dock parsing and system hotkey integration tests, including real keyboard event delivery.

## [0.2.0] - 2026-08-15

- Added independent natural or reversed scrolling for trackpads and mouse wheels.
- Kept local development signatures stable so Accessibility access survives rebuilds.
- Added a clear runtime status for scroll direction control.
- Stopped requesting Accessibility access automatically when scroll control is toggled.

## [0.1.1] - 2026-08-13

- Hid the Dock icon after the settings window closes while keeping MacEase available in the menu bar.
- Rebuilt the app icon with centered geometry, full coverage, and clean edges.

## [0.1.0] - 2026-08-13

- Added Finder context-menu actions for creating empty files and folders.
- Added automatic in-place renaming for newly created items.
- Added a menu bar interface with English and Simplified Chinese localization.

[0.1.0]: https://github.com/lkpsg/MacEase/releases/tag/v0.1.0
[0.1.1]: https://github.com/lkpsg/MacEase/compare/v0.1.0...1018cb2
[0.2.0]: https://github.com/lkpsg/MacEase/compare/1018cb2...82e80d9
[0.3.0]: https://github.com/lkpsg/MacEase/compare/82e80d9...HEAD
