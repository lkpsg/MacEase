#!/bin/sh

set -eu

# Requires a logged-in macOS desktop and temporarily reserves Command + 1–9/0.
# Quit utilities using those shortcuts before running. --post-key-events also
# tests CGEvent keyboard delivery and requires event-posting permission.
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d /tmp/macease-dock-tests.XXXXXX)
trap 'rm -r "$test_root"' EXIT
sdk_root=$(xcrun --show-sdk-path)

swiftc -emit-library -static -parse-as-library \
    -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    "$project_root"/Sources/MacEaseCore/*.swift \
    -emit-module -module-name MacEaseCore \
    -emit-module-path "$test_root/MacEaseCore.swiftmodule" \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -o "$test_root/libMacEaseCore.a"

swiftc -parse-as-library \
    -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    "$project_root/MacEaseApp/DockShortcutController.swift" \
    "$project_root/Tests/DockShortcutTests/main.swift" \
    -I "$test_root" -L "$test_root" -lMacEaseCore \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -framework AppKit -framework Carbon \
    -o "$test_root/DockShortcutTests"

"$test_root/DockShortcutTests" "$@"
