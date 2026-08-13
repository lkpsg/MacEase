#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
master_icon="$project_root/Design/MacEase-AppIcon-Master.png"
app_icon_set="$project_root/MacEaseApp/Assets.xcassets/AppIcon.appiconset"
menu_icon_set="$project_root/MacEaseApp/Assets.xcassets/MenuBarIcon.imageset"
runtime_icon="$project_root/MacEaseApp/Resources/AppIcon.icns"
runtime_menu_icon="$project_root/MacEaseApp/Resources/MenuBarIconTemplate.png"
python_runtime=${CODEX_WORKSPACE_PYTHON:-$(command -v python3 || true)}
iconset_dir=$(mktemp -d /tmp/macease-iconset.XXXXXX)/AppIcon.iconset

cleanup() {
    rm -r "$(dirname "$iconset_dir")"
}
trap cleanup EXIT

if [ -z "$python_runtime" ] || [ ! -x "$python_runtime" ]; then
    echo "错误：找不到 Python 3。" >&2
    exit 1
fi

if ! "$python_runtime" -c 'import PIL' >/dev/null 2>&1; then
    echo "错误：图标生成需要 Pillow；请先执行 python3 -m pip install Pillow。" >&2
    exit 1
fi

mkdir -p "$iconset_dir"

"$python_runtime" - "$master_icon" "$app_icon_set" "$menu_icon_set" \
    "$runtime_menu_icon" "$iconset_dir" <<'PY'
from pathlib import Path
import sys
from PIL import Image, ImageDraw

master_path = Path(sys.argv[1])
app_icon_set = Path(sys.argv[2])
menu_icon_set = Path(sys.argv[3])
runtime_menu_icon = Path(sys.argv[4])
iconset_dir = Path(sys.argv[5])

master = Image.open(master_path).convert("RGBA")
if master.width != master.height:
    raise SystemExit("App icon master must be square")

resampling = Image.Resampling.LANCZOS
app_sizes = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}
for filename, size in app_sizes.items():
    resized = master.resize((size, size), resampling)
    resized.save(app_icon_set / filename, optimize=True)
    resized.save(iconset_dir / filename, optimize=True)

def draw_menu_icon(pixel_size: int) -> Image.Image:
    supersampling = 8
    canvas_size = pixel_size * supersampling
    scale = canvas_size / 18
    center = canvas_size / 2
    image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    petal = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(petal)
    box = (
        round(6.65 * scale),
        round(1.5 * scale),
        round(11.35 * scale),
        round(9.1 * scale),
    )
    draw.rounded_rectangle(
        box,
        radius=round(2.35 * scale),
        fill=(0, 0, 0, 255),
    )

    for angle in (0, 120, 240):
        rotated = petal.rotate(
            angle,
            resample=Image.Resampling.BICUBIC,
            center=(center, center),
        )
        image.alpha_composite(rotated)

    return image.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)

for filename, size in (("MenuBarIcon.png", 18), ("MenuBarIcon@2x.png", 36), ("MenuBarIcon@3x.png", 54)):
    draw_menu_icon(size).save(menu_icon_set / filename, optimize=True)

draw_menu_icon(36).save(runtime_menu_icon, optimize=True)
PY

iconutil -c icns "$iconset_dir" -o "$runtime_icon"

echo "已从 $master_icon 生成 AppIcon 与菜单栏模板图标。"
