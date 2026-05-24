from PIL import Image
import os, shutil, subprocess

os.chdir(os.path.dirname(os.path.abspath(__file__)))

SRC = os.path.expanduser("~/Desktop/ScreenShot_2026-05-24_212017_713.png")
ICONSET = "DeepSeekBalance/Assets/AppIcon.iconset"
ICNS = "DeepSeekBalance/Assets/AppIcon.icns"

os.makedirs(ICONSET, exist_ok=True)

img = Image.open(SRC).convert("RGBA")

sizes = {
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

for name, size in sizes.items():
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(os.path.join(ICONSET, name), "PNG")
    print(f"  {name} ({size}x{size})")

subprocess.run(["iconutil", "-c", "icns", "-o", ICNS, ICONSET], check=True)
shutil.rmtree(ICONSET)
print(f"Done: {ICNS}")
