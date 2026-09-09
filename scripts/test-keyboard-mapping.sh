#!/bin/sh

set -eu

# Tests real CGEvent/NSEvent payloads and native text navigation in-process;
# does not install a global tap by default. --post-key-events also exercises
# the system event stream using tagged events consumed before app delivery.
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d /tmp/macease-keyboard-tests.XXXXXX)
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
    "$project_root/MacEaseApp/KeyboardEventMapper.swift" \
    "$project_root/MacEaseApp/KeyboardMappingController.swift" \
    "$project_root"/Tests/KeyboardMappingTests/*.swift \
    -I "$test_root" -L "$test_root" -lMacEaseCore \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -framework AppKit -o "$test_root/KeyboardMappingTests"

"$test_root/KeyboardMappingTests" "$@"
