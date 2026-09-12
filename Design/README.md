# MacEase icon

The app and menu bar use the approved [Loop v2 concept](Concepts/MacEase-Loop-v2.md).

`MacEase-AppIcon.svg` is the production source. The three mark contours follow the accepted design; the ivory tile has transparent outer margins. The `mark` group is also the source for the monochrome menu bar template. Its `data-menu-view-box` defines the template's optical padding.

Run `./scripts/generate-icon-assets.sh` on macOS to regenerate the app and menu bar PNGs, ICNS and generated menu bar SVG. The script uses `sips`, `iconutil` and Python's standard XML library. It does not require Pillow or alter the artwork through symmetry operations.
