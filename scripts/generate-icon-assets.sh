#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
master_svg="$project_root/Design/MacEase-AppIcon.svg"
master_png="$project_root/Design/MacEase-AppIcon-Master.png"
menu_svg="$project_root/Design/MacEase-MenuBarIcon.svg"
menu_master="$project_root/Design/MacEase-MenuBarIcon-Master.png"
app_icon_set="$project_root/MacEaseApp/Assets.xcassets/AppIcon.appiconset"
menu_icon_set="$project_root/MacEaseApp/Assets.xcassets/MenuBarIcon.imageset"
runtime_icon="$project_root/MacEaseApp/Resources/AppIcon.icns"
runtime_menu_icon="$project_root/MacEaseApp/Resources/MenuBarIconTemplate.png"
python_runtime=${CODEX_WORKSPACE_PYTHON:-$(command -v python3 || true)}
temporary_root=$(mktemp -d /tmp/macease-iconset.XXXXXX)
iconset_dir="$temporary_root/AppIcon.iconset"

cleanup() {
    rm -r "$temporary_root"
}
trap cleanup EXIT

if [ -z "$python_runtime" ] || [ ! -x "$python_runtime" ]; then
    echo "错误：找不到 Python 3。" >&2
    exit 1
fi
for utility in sips iconutil; do
    if ! command -v "$utility" >/dev/null 2>&1; then
        echo "错误：找不到 $utility，无法生成图标。" >&2
        exit 1
    fi
done

# Derive the template from the same vector mark, preserving its silhouette.
# Only XML is processed here; artwork pixels are never mirrored or recoloured.
"$python_runtime" - "$master_svg" "$menu_svg" <<'PY'
import copy
import sys
import xml.etree.ElementTree as ET

namespace = "http://www.w3.org/2000/svg"
ET.register_namespace("", namespace)
source = ET.parse(sys.argv[1]).getroot()
mark = source.find(".//*[@id='mark']")
if mark is None or "data-menu-view-box" not in mark.attrib:
    raise SystemExit("App icon must contain a mark with data-menu-view-box")
mark = copy.deepcopy(mark)
view_box = mark.attrib.pop("data-menu-view-box")
mark.set("fill", "#000000")
root = ET.Element(f"{{{namespace}}}svg", {
    "width": "1024", "height": "1024", "viewBox": view_box,
})
ET.SubElement(root, f"{{{namespace}}}title").text = "MacEase menu bar icon"
root.append(mark)
ET.ElementTree(root).write(sys.argv[2], encoding="unicode")
PY

sips -s format png "$master_svg" --out "$master_png" >/dev/null
sips -s format png "$menu_svg" --out "$menu_master" >/dev/null
mkdir -p "$iconset_dir"

while read -r filename size; do
    if [ "$size" = 1024 ]; then
        cp "$master_png" "$iconset_dir/$filename"
    else
        sips -z "$size" "$size" "$master_png" --out "$iconset_dir/$filename" >/dev/null
    fi
    cp "$iconset_dir/$filename" "$app_icon_set/$filename"
done <<'SIZES'
icon_16x16.png 16
icon_16x16@2x.png 32
icon_32x32.png 32
icon_32x32@2x.png 64
icon_128x128.png 128
icon_128x128@2x.png 256
icon_256x256.png 256
icon_256x256@2x.png 512
icon_512x512.png 512
icon_512x512@2x.png 1024
SIZES

while read -r filename size; do
    sips -z "$size" "$size" "$menu_master" --out "$menu_icon_set/$filename" >/dev/null
done <<'SIZES'
MenuBarIcon.png 18
MenuBarIcon@2x.png 36
MenuBarIcon@3x.png 54
SIZES
cp "$menu_icon_set/MenuBarIcon@2x.png" "$runtime_menu_icon"
iconutil -c icns "$iconset_dir" -o "$runtime_icon"
echo "已生成 App 图标和同形状的菜单栏模板图标。"
