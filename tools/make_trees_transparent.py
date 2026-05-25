"""Remove baked-in checkerboard from treesandstufftransparent.png (real alpha)."""
from pathlib import Path

from PIL import Image

SRC = Path(__file__).resolve().parents[1] / "assets" / "treesandstufftransparent.png"


def is_background(r: int, g: int, b: int) -> bool:
    mx = max(r, g, b)
    mn = min(r, g, b)
    spread = mx - mn
    # Checkerboard greys/whites: low colour spread, fairly bright.
    if mx < 150:
        return False
    if spread > 48:
        return False
    if mx > 235 and spread < 28:
        return True
    if 165 <= mx <= 235 and spread < 32:
        return True
    return False


def main() -> None:
    img = Image.open(SRC).convert("RGBA")
    px = img.load()
    w, h = img.size
    cleared = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_background(r, g, b):
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
    img.save(SRC)
    print(f"Saved {SRC} ({w}x{h}), cleared {cleared} pixels")


if __name__ == "__main__":
    main()
