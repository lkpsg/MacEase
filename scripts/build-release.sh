#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output_root=${1:-"$project_root/dist"}
. "$project_root/scripts/version.sh"
load_version "$project_root"

stage_root=$(mktemp -d /tmp/macease-release.XXXXXX)
cleanup() {
    rm -r "$stage_root"
}
trap cleanup EXIT

mkdir -p "$output_root"
build_root="$stage_root/build"
app_source="$build_root/MacEase.app"
app_name="MacEase.app"
archive_name="MacEase-$MACEASE_TAG-arm64"
dmg_path="$output_root/$archive_name.dmg"
checksum_path="$dmg_path.sha256"

MACEASE_BUILD_CONFIGURATION=release \
    "$project_root/scripts/build-app.sh" "$build_root" >/dev/null

stage="$stage_root/dmg"
mkdir -p "$stage"
ditto "$app_source" "$stage/$app_name"
ln -s /Applications "$stage/Applications"

rm -f "$dmg_path" "$checksum_path"
hdiutil create \
    -volname "MacEase $MACEASE_VERSION" \
    -srcfolder "$stage" \
    -ov -format UDZO \
    "$dmg_path" >/dev/null

codesign --verify --deep --strict --verbose=2 "$stage/$app_name"
(
    cd "$output_root"
    shasum -a 256 "$(basename "$dmg_path")" > "$(basename "$checksum_path")"
)

echo "$dmg_path"
echo "$checksum_path"
