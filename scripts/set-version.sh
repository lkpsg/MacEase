#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$project_root/scripts/version.sh"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <semantic-version> [build-number]" >&2
    exit 2
fi

new_version=$1
new_build=${2:-}

if ! printf '%s' "$new_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$'; then
    echo "Version must use semantic versioning, for example 0.2.0." >&2
    exit 2
fi

version_file=$(version_config_path "$project_root")
current_build=$(read_version_value CURRENT_PROJECT_VERSION "$version_file")
if [ -z "$new_build" ]; then
    new_build=$((current_build + 1))
fi
if ! printf '%s' "$new_build" | grep -Eq '^[1-9][0-9]*$'; then
    echo "Build number must be a positive integer." >&2
    exit 2
fi

sed -i '' \
    -e "s/^MARKETING_VERSION = .*/MARKETING_VERSION = $new_version/" \
    -e "s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $new_build/" \
    "$version_file"

echo "MacEase version set to $new_version ($new_build)."
