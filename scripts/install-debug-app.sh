#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output_root=${1:-"$project_root/../outputs"}
built_app="$output_root/MacEase-Debug.app"
installed_app="/Applications/MacEase.app"
extension_relative_path="Contents/PlugIns/MacEaseFinderExtension.appex"
extension_identifier="com.lkpsg.MacEase.FinderExtension"

if [ ! -w /Applications ]; then
    echo "错误：当前用户无权写入 /Applications。" >&2
    echo "请先构建，再手动把 $built_app 复制为 /Applications/MacEase.app。" >&2
    exit 1
fi

"$project_root/scripts/build-debug-app.sh" "$output_root"

pkill -x MacEase 2>/dev/null || true

if [ -e "$installed_app" ]; then
    backup_root="$project_root/work"
    backup_app="$backup_root/MacEase-before-install-$(date +%Y%m%d-%H%M%S).app"
    mkdir -p "$backup_root"
    pluginkit -r "$installed_app/$extension_relative_path" >/dev/null 2>&1 || true
    mv "$installed_app" "$backup_app"
    echo "旧版已备份到：$backup_app"
fi

pluginkit -r "$built_app/$extension_relative_path" >/dev/null 2>&1 || true
ditto "$built_app" "$installed_app"
codesign --verify --deep --strict --verbose=2 "$installed_app"
pluginkit -a "$installed_app/$extension_relative_path"
pluginkit -e use -i "$extension_identifier"

killall Finder 2>/dev/null || true
open "$installed_app"

echo "MacEase 已安装并启动：$installed_app"
