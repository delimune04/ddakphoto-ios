#!/usr/bin/env python3
"""Render the app's original geometric icon. Requires Pillow; no remote assets."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
assets = root / "DdakPhoto/Resources/Assets.xcassets"
icon_folder = assets / "AppIcon.appiconset"
icon_folder.mkdir(parents=True, exist_ok=True)
image = Image.new("RGB", (1024, 1024), "#20695D")
draw = ImageDraw.Draw(image)
draw.rounded_rectangle((251, 255, 792, 796), radius=82, fill="#164F47")
draw.rounded_rectangle((214, 214, 756, 756), radius=82, fill="#F6F5F1")
draw.rounded_rectangle((255, 255, 715, 715), radius=49, fill="#E7F0CB")
draw.ellipse((542, 320, 631, 409), fill="#20695D")
draw.polygon([(255, 629), (402, 434), (516, 587), (584, 498), (715, 641), (715, 715), (255, 715)], fill="#20695D")
# Inward arrows keep the mark readable even at home-screen size.
draw.line([(858, 169), (759, 268)], fill="#F6F5F1", width=35)
draw.line([(756, 202), (756, 272), (826, 272)], fill="#F6F5F1", width=35, joint="curve")
draw.line([(164, 853), (264, 753)], fill="#F6F5F1", width=35)
draw.line([(198, 755), (270, 755), (270, 826)], fill="#F6F5F1", width=35, joint="curve")
image.save(icon_folder / "AppIcon.png", optimize=True)
(icon_folder / "Contents.json").write_text(json.dumps({
    "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
    "info": {"author": "xcode", "version": 1}
}, indent=2) + "\n")
(assets / "Contents.json").write_text('{"info":{"author":"xcode","version":1}}\n')
color_folder = assets / "AccentColor.colorset"
color_folder.mkdir(exist_ok=True)
(color_folder / "Contents.json").write_text(json.dumps({
    "colors": [{"idiom": "universal", "color": {"color-space": "srgb", "components": {
        "red": "0.125", "green": "0.412", "blue": "0.365", "alpha": "1.000"
    }}}], "info": {"author": "xcode", "version": 1}
}, indent=2) + "\n")
print("Generated opaque 1024×1024 app icon and asset catalog.")
