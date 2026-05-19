#!/usr/bin/env python3
"""기존 자물쇠 아이콘 PNG — 3D 질감 유지, 색만 치환 (베이지 배경 · 세이지 그린 잠금)."""

from __future__ import annotations

import colorsys
import sys
from pathlib import Path

from PIL import Image

BG = (246, 244, 241)
BG_SHADOW = (228, 224, 216)
# 원본: 배경 L < 52, 잠금 L >= 52 (베이지 악센트는 별도)
BG_LUMA_MAX = 52.0


def luma(r: int, g: int, b: int) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def is_warm_accent(h: float, s: float, v: float, r: int, g: int) -> bool:
    return 0.04 < h < 0.13 and s > 0.12 and v > 0.32 and r > g + 15


def luma_to_beige(L: float) -> tuple[int, int, int]:
    t = (L - 2.0) / (BG_LUMA_MAX - 2.0)
    t = max(0.0, min(1.0, t))
    return tuple(int(BG_SHADOW[i] + (BG[i] - BG_SHADOW[i]) * t) for i in range(3))


def blue_hue_to_green(h: float) -> float:
    if h < 0.42:
        return 0.30
    t = (h - 0.42) / (0.74 - 0.42)
    t = max(0.0, min(1.0, t))
    return 0.28 + t * (0.40 - 0.28)


def recolor_pixel(r: int, g: int, b: int, a: int) -> tuple[int, int, int, int]:
    if a < 16:
        return r, g, b, 0

    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    L = luma(r, g, b)

    if is_warm_accent(h, s, v, r, g):
        return r, g, b, a

    if L < BG_LUMA_MAX:
        return (*luma_to_beige(L), a)

    new_h = blue_hue_to_green(h)
    nr, ng, nb = colorsys.hsv_to_rgb(new_h, s, v)
    return int(nr * 255), int(ng * 255), int(nb * 255), a


def recolor_image(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    out = Image.new("RGBA", im.size)
    px = im.load()
    ox = out.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            ox[x, y] = recolor_pixel(*px[x, y])
    im.close()
    out.save(path, "PNG")
    print(f"recolored {path}")


def main() -> None:
    root = Path(__file__).resolve().parents[1] / "Anchor" / "Assets.xcassets"
    targets = [
        root / "AppIcon.appiconset" / "AppIcon-1024.png",
        root / "SplashIcon.imageset" / "SplashIcon.png",
    ]
    for p in targets:
        if not p.exists():
            print(f"missing: {p}", file=sys.stderr)
            sys.exit(1)
        recolor_image(p)


if __name__ == "__main__":
    main()
