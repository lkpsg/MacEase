#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_root"

echo "==> Validating property lists"
plutil -lint Config/MacEase-Info.plist
plutil -lint Config/MacEaseFinderExtension-Info.plist
plutil -lint Config/MacEaseFinderExtension.entitlements
plutil -lint \
    MacEaseApp/Resources/en.lproj/Localizable.strings \
    MacEaseApp/Resources/en.lproj/InfoPlist.strings \
    MacEaseApp/Resources/zh-Hans.lproj/Localizable.strings \
    MacEaseApp/Resources/zh-Hans.lproj/InfoPlist.strings \
    MacEaseFinderExtension/Resources/en.lproj/Localizable.strings \
    MacEaseFinderExtension/Resources/en.lproj/InfoPlist.strings \
    MacEaseFinderExtension/Resources/zh-Hans.lproj/Localizable.strings \
    MacEaseFinderExtension/Resources/zh-Hans.lproj/InfoPlist.strings

echo "==> Checking generated Xcode project"
xcodegen generate

sdk_root=$(xcrun --show-sdk-path)
typecheck_dir=$(mktemp -d /tmp/macease-typecheck.XXXXXX)
trap 'rm -r "$typecheck_dir"' EXIT

echo "==> Type-checking MacEaseCore"
swiftc -emit-module -parse-as-library \
    -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    -module-name MacEaseCore Sources/MacEaseCore/*.swift \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -emit-module-path "$typecheck_dir/MacEaseCore.swiftmodule"

echo "==> Type-checking Finder extension"
swiftc -typecheck \
    -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    MacEaseFinderExtension/FinderSync.swift \
    -module-name MacEaseFinderExtension -I "$typecheck_dir" \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -framework AppKit -framework FinderSync -application-extension

echo "==> Type-checking main app"
swiftc -typecheck \
    -swift-version 6 -strict-concurrency=complete -warnings-as-errors \
    MacEaseApp/*.swift -module-name MacEase -I "$typecheck_dir" \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -framework SwiftUI -framework FinderSync

echo "==> Building and running file-system smoke tests"
swift build -Xswiftc -gnone
.build/arm64-apple-macosx/debug/MacEaseCoreSmokeTests

echo "==> Verification complete"
