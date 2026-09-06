#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output_root=${1:-"$project_root/outputs"}
built_app="$output_root/MacEase-Debug.app"
installed_app="/Applications/MacEase.app"

if [ ! -w /Applications ]; then
    echo "错误：当前用户无权写入 /Applications。" >&2
    echo "请先构建，再手动把 $built_app 复制为 /Applications/MacEase.app。" >&2
    exit 1
fi

"$project_root/scripts/build-debug-app.sh" "$output_root"

if pgrep -x MacEase >/dev/null; then
    osascript -e 'tell application "MacEase" to quit' >/dev/null
    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        if ! pgrep -x MacEase >/dev/null; then break; fi
        sleep 0.2
    done
    if pgrep -x MacEase >/dev/null; then
        echo "MacEase 尚未退出，请关闭应用后重试安装。" >&2
        exit 1
    fi
fi

ditto "$built_app" "$installed_app"
codesign --verify --deep --strict --verbose=2 "$installed_app"

open "$installed_app"
killall Finder 2>/dev/null || true

echo "MacEase 已安装并启动：$installed_app"
