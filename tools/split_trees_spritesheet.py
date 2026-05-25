"""Split treesandstufftransparent.png into individual transparent PNGs."""
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "treesandstufftransparent.png"
OUT_DIR = ROOT / "assets" / "trees"

# Rough horizontal bands (from sprite sheet layout).
BANDS = [
    ("tree_large", 0, 218),
    ("tree_small", 218, 318),
    ("stumps_log", 318, 518),
    ("bushes_rocks", 518, 768),
]

PADDING = 4
MIN_AREA = 800
EROSION = 8

BAND_SETTINGS = {
    "tree_large": {"min_area": 2500, "erosion": 12},
    "tree_small": {"min_area": 2800, "erosion": 11},
    "stumps_log": {"min_area": 900, "erosion": 8},
    "bushes_rocks": {"min_area": 500, "erosion": 6},
}


def foreground_mask(arr: np.ndarray) -> np.ndarray:
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    spread = mx - mn
    bg = ((mx > 140) & (spread < 55)) | (alpha < 40)
    return ~bg


def clean_background(img: Image.Image) -> Image.Image:
    arr = np.array(img.convert("RGBA"))
    fg = foreground_mask(arr)
    arr[~fg, 3] = 0
    arr[~fg, :3] = 0
    return Image.fromarray(arr)


def extract_sprites(
    band_img: Image.Image, min_area: int = MIN_AREA, erosion: int = EROSION
) -> list[Image.Image]:
    arr = np.array(band_img)
    fg = foreground_mask(arr)
    core = ndimage.binary_erosion(fg, iterations=erosion)
    labeled, count = ndimage.label(core)
    sprites: list[tuple[int, int, int, int, int]] = []

    for label_id in range(1, count + 1):
        ys, xs = np.where(labeled == label_id)
        if xs.size < min_area:
            continue
        x0, x1 = int(xs.min()), int(xs.max()) + 1
        y0, y1 = int(ys.min()), int(ys.max()) + 1
        # Expand bbox using original foreground in the region.
        region = fg[max(0, y0 - 20) : y1 + 20, max(0, x0 - 20) : x1 + 20]
        if not region.any():
            continue
        ry, rx = np.where(fg[y0:y1, x0:x1])
        if rx.size == 0:
            continue
        fx0 = x0 + int(rx.min())
        fx1 = x0 + int(rx.max()) + 1
        fy0 = y0 + int(ry.min())
        fy1 = y0 + int(ry.max()) + 1
        sprites.append((fx0, fy0, fx1, fy1, int(fg[fy0:fy1, fx0:fx1].sum())))

    # Drop duplicates / nested boxes (keep larger).
    sprites.sort(key=lambda s: s[4], reverse=True)
    kept: list[tuple[int, int, int, int]] = []
    for x0, y0, x1, y1, _area in sprites:
        if any(
            x0 >= kx0 and y0 >= ky0 and x1 <= kx1 and y1 <= ky1
            for kx0, ky0, kx1, ky1 in kept
        ):
            continue
        kept.append((x0, y0, x1, y1))

    kept.sort(key=lambda b: (b[1], b[0]))
    out: list[Image.Image] = []
    w, h = band_img.size
    for x0, y0, x1, y1 in kept:
        x0 = max(0, x0 - PADDING)
        y0 = max(0, y0 - PADDING)
        x1 = min(w, x1 + PADDING)
        y1 = min(h, y1 + PADDING)
        crop = band_img.crop((x0, y0, x1, y1))
        c_arr = np.array(crop)
        c_fg = foreground_mask(c_arr)
        c_arr[~c_fg, 3] = 0
        c_arr[~c_fg, :3] = 0
        out.append(Image.fromarray(c_arr))
    return out


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sheet = clean_background(Image.open(SRC))
    sheet.save(SRC)  # keep master sheet fully transparent outside sprites

    index = 0
    for band_name, y0, y1 in BANDS:
        band = sheet.crop((0, y0, sheet.width, y1))
        cfg = BAND_SETTINGS.get(band_name, {})
        sprites = extract_sprites(
            band,
            min_area=cfg.get("min_area", MIN_AREA),
            erosion=cfg.get("erosion", EROSION),
        )
        for i, sprite in enumerate(sprites, start=1):
            index += 1
            path = OUT_DIR / f"{band_name}_{i:02d}.png"
            sprite.save(path)
            print("wrote", path.name, sprite.size)

    print(f"Done: {index} sprites in {OUT_DIR}")


if __name__ == "__main__":
    main()
