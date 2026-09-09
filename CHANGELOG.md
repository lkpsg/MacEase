# Changelog

All notable changes to MacEase are documented here. The project follows [Semantic Versioning](https://semver.org/).

## [0.4.0] - 2026-09-09

- Added optional Command + I/J/K/L mappings to plain up/left/down/right arrows, with key repeat and paired key releases.
- Added a keyboard mapping settings page, menu bar toggle, Accessibility guidance and English/Simplified Chinese strings.
- Added keyboard event and native text navigation tests to the standard verification script.
- Added optional system event integration tests with a separate key-event sender and isolated preferences.

## [0.3.1] - 2026-09-06

- Replaced the long settings page with sidebar navigation and dedicated Finder, scrolling, Dock shortcut, permissions, and about pages.
- Made the settings window resizable and restored its last page, size, and position.
- Collapsed detailed help, preserved disabled feature options, and showed permission or shortcut warnings only when relevant.
- Simplified the menu bar to quick feature toggles, Open Settings, and Quit.
- Made local installation wait for the previous app process to exit before replacing and relaunching it.

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
[0.3.0]: https://github.com/lkpsg/MacEase/compare/82e80d9...e11f50e
[0.3.1]: https://github.com/lkpsg/MacEase/compare/e11f50e...6a388a8
[0.4.0]: https://github.com/lkpsg/MacEase/compare/6a388a8...v0.4.0
