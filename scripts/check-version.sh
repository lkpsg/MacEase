#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$project_root/scripts/version.sh"
load_version "$project_root"

assert_plist_uses_version_variables() {
    plist=$1
    short_version=$(plutil -extract CFBundleShortVersionString raw "$plist")
    build_version=$(plutil -extract CFBundleVersion raw "$plist")

    [ "$short_version" = '$(MARKETING_VERSION)' ] || {
        echo "$plist does not use MARKETING_VERSION." >&2
        exit 1
    }
    [ "$build_version" = '$(CURRENT_PROJECT_VERSION)' ] || {
        echo "$plist does not use CURRENT_PROJECT_VERSION." >&2
        exit 1
    }
}

assert_plist_uses_version_variables "$project_root/Config/MacEase-Info.plist"
assert_plist_uses_version_variables "$project_root/Config/MacEaseFinderExtension-Info.plist"

if [ -n "${GITHUB_REF_NAME:-}" ] && [ "${GITHUB_REF_TYPE:-}" = tag ]; then
    if [ "$GITHUB_REF_NAME" != "$MACEASE_TAG" ]; then
        echo "Tag $GITHUB_REF_NAME does not match version $MACEASE_TAG." >&2
        exit 1
    fi
fi

echo "MacEase version $MACEASE_VERSION ($MACEASE_BUILD), tag $MACEASE_TAG."
