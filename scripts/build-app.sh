#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output_root=${1:-"$project_root/outputs"}
configuration=${MACEASE_BUILD_CONFIGURATION:-debug}

case "$configuration" in
    debug)
        app_bundle="$output_root/MacEase-Debug.app"
        optimization_flags=''
        ;;
    release)
        app_bundle="$output_root/MacEase.app"
        optimization_flags='-O -whole-module-optimization'
        ;;
    *)
        echo "Unknown build configuration: $configuration" >&2
        exit 2
        ;;
esac

extension_bundle="$app_bundle/Contents/PlugIns/MacEaseFinderExtension.appex"
app_executable="$app_bundle/Contents/MacOS/MacEase"
extension_executable="$extension_bundle/Contents/MacOS/MacEaseFinderExtension"
sdk_root=$(xcrun --show-sdk-path)
module_dir=$(mktemp -d /tmp/macease-module.XXXXXX)
. "$project_root/scripts/version.sh"
load_version "$project_root"

cleanup() {
    rm -r "$module_dir"
}
trap cleanup EXIT

if [ -e "$app_bundle" ]; then
    rm -r "$app_bundle"
fi
mkdir -p \
    "$app_bundle/Contents/MacOS" \
    "$app_bundle/Contents/Resources" \
    "$extension_bundle/Contents/MacOS" \
    "$extension_bundle/Contents/Resources"

cp "$project_root/Config/MacEase-Info.plist" "$app_bundle/Contents/Info.plist"
cp "$project_root/Config/MacEaseFinderExtension-Info.plist" "$extension_bundle/Contents/Info.plist"
cp "$project_root/MacEaseApp/Resources/AppIcon.icns" "$app_bundle/Contents/Resources/AppIcon.icns"
cp "$project_root/MacEaseApp/Resources/MenuBarIconTemplate.png" "$app_bundle/Contents/Resources/MenuBarIconTemplate.png"
cp -R "$project_root/MacEaseApp/Resources/en.lproj" "$app_bundle/Contents/Resources/"
cp -R "$project_root/MacEaseApp/Resources/zh-Hans.lproj" "$app_bundle/Contents/Resources/"
cp -R "$project_root/MacEaseFinderExtension/Resources/en.lproj" "$extension_bundle/Contents/Resources/"
cp -R "$project_root/MacEaseFinderExtension/Resources/zh-Hans.lproj" "$extension_bundle/Contents/Resources/"

plutil -replace CFBundleExecutable -string MacEase "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.lkpsg.MacEase "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleName -string MacEase "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleIconFile -string AppIcon "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$MACEASE_VERSION" "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$MACEASE_BUILD" "$app_bundle/Contents/Info.plist"
plutil -replace LSUIElement -bool false "$app_bundle/Contents/Info.plist"
plutil -replace CFBundleExecutable -string MacEaseFinderExtension "$extension_bundle/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.lkpsg.MacEase.FinderExtension "$extension_bundle/Contents/Info.plist"
plutil -replace CFBundleName -string MacEaseFinderExtension "$extension_bundle/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$MACEASE_VERSION" "$extension_bundle/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$MACEASE_BUILD" "$extension_bundle/Contents/Info.plist"
plutil -replace NSExtension.NSExtensionPrincipalClass -string MacEaseFinderExtension.FinderSync "$extension_bundle/Contents/Info.plist"

# Intentional word splitting lets the release configuration add two compiler flags.
# shellcheck disable=SC2086
swiftc $optimization_flags -emit-library -static -parse-as-library "$project_root"/Sources/MacEaseCore/*.swift \
    -emit-module -module-name MacEaseCore \
    -emit-module-path "$module_dir/MacEaseCore.swiftmodule" \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -o "$module_dir/libMacEaseCore.a"

# shellcheck disable=SC2086
swiftc $optimization_flags -emit-executable -parse-as-library "$project_root"/MacEaseApp/*.swift \
    -module-name MacEase -I "$module_dir" -L "$module_dir" -lMacEaseCore \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -framework AppKit -framework ApplicationServices -framework FinderSync \
    -framework SwiftUI -o "$app_executable"

# shellcheck disable=SC2086
swiftc $optimization_flags -emit-executable -parse-as-library "$project_root/MacEaseFinderExtension/FinderSync.swift" \
    -module-name MacEaseFinderExtension -I "$module_dir" -L "$module_dir" -lMacEaseCore \
    -target arm64-apple-macosx13.0 -sdk "$sdk_root" \
    -framework AppKit -framework FinderSync -application-extension \
    -Xlinker -e -Xlinker _NSExtensionMain -o "$extension_executable"

codesign --force --sign - \
    --entitlements "$project_root/Config/MacEaseFinderExtension.entitlements" \
    "$extension_bundle"
codesign --force --sign - "$app_bundle"
codesign --verify --deep --strict --verbose=2 "$app_bundle"

echo "$app_bundle"
