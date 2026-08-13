#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output_root=${1:-"$project_root/outputs"}

MACEASE_BUILD_CONFIGURATION=debug \
    "$project_root/scripts/build-app.sh" "$output_root"
