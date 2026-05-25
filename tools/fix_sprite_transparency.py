"""Remove checkerboard / flat backgrounds from a sprite PNG (real alpha channel)."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def is_background(r: int, g: int, b: int) -> bool:
    mx = max(r, g, b)
    mn = min(r, g, b)
    spread = mx - mn
    # Neutral greys/whites (light or dark checkerboard).
    if spread <= 22 and 68 <= mx <= 252:
        return True
    # Near-black fringe from export.
    if mx < 68 and spread < 12:
        return True
    return False


def clean_image(path: Path) -> int:
    img = Image.open(path).convert("RGBA")
    px = img.load()
    cleared = 0
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if is_background(r, g, b):
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
    img.save(path)
    return cleared


def main() -> None:
    targets = sys.argv[1:] or [str(ROOT / "assets" / "trees" / "stumps_log_01.png")]
    for raw in targets:
        path = Path(raw)
        n = clean_image(path)
        print(f"{path.name}: cleared {n} pixels")


if __name__ == "__main__":
    main()
