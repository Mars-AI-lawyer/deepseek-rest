from PIL import Image
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

img = Image.open("ScreenShot_2026-05-20_215846_476.png").convert("RGBA")
pixels = img.load()

for y in range(img.height):
    for x in range(img.width):
        r, g, b, a = pixels[x, y]
        if r > 220 and g > 220 and b > 220:
            pixels[x, y] = (r, g, b, 0)
        else:
            pixels[x, y] = (r, g, b, 255)

out_dir = "DeepSeekBalance/Assets"
os.makedirs(out_dir, exist_ok=True)

sizes = {"status_icon.png": (18, 18), "status_icon@2x.png": (36, 36), "status_icon@3x.png": (54, 54)}
for name, size in sizes.items():
    resized = img.resize(size, Image.LANCZOS)
    resized.save(os.path.join(out_dir, name), "PNG")
    print(f"Saved {name} ({size[0]}x{size[1]})")
