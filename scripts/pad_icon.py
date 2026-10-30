#!/usr/bin/env python3
"""
Pad icon to 65% scale on 1024x1024 transparent canvas.
Usage: python3 scripts/pad_icon.py <input> <output>
"""
import sys
from PIL import Image

def pad_icon(input_path: str, output_path: str, scale: float = 0.65, canvas_size: int = 1024):
    img = Image.open(input_path).convert("RGBA")
    # Trim transparent edges
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    # Resize to scale of canvas
    new_size = int(canvas_size * scale)
    img.thumbnail((new_size, new_size), Image.LANCZOS)
    # Create transparent canvas
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    # Center paste
    x = (canvas_size - img.width) // 2
    y = (canvas_size - img.height) // 2
    canvas.paste(img, (x, y), img)
    canvas.save(output_path, "PNG")
    print(f"Saved padded icon: {output_path} ({img.width}x{img.height} on {canvas_size}x{canvas_size})")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 pad_icon.py <input> <output>")
        sys.exit(1)
    pad_icon(sys.argv[1], sys.argv[2])