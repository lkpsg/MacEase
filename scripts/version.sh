#!/bin/sh

version_config_path() {
    printf '%s/Config/Version.xcconfig\n' "$1"
}

read_version_value() {
    key=$1
    file=$2
    awk -F= -v key="$key" '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            value = $2
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            print value
            exit
        }
    ' "$file"
}

load_version() {
    project_root=$1
    version_file=$(version_config_path "$project_root")

    MACEASE_VERSION=$(read_version_value MARKETING_VERSION "$version_file")
    MACEASE_BUILD=$(read_version_value CURRENT_PROJECT_VERSION "$version_file")

    if ! printf '%s' "$MACEASE_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$'; then
        echo "Invalid MARKETING_VERSION in $version_file: $MACEASE_VERSION" >&2
        return 1
    fi
    if ! printf '%s' "$MACEASE_BUILD" | grep -Eq '^[1-9][0-9]*$'; then
        echo "Invalid CURRENT_PROJECT_VERSION in $version_file: $MACEASE_BUILD" >&2
        return 1
    fi

    MACEASE_TAG="v$MACEASE_VERSION"
    export MACEASE_VERSION MACEASE_BUILD MACEASE_TAG
}
