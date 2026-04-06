#!/usr/bin/env python3
"""
Generate StoryTeller app icons.

Produces:
  assets/icon.png            – 1024×1024 full icon (background + graphic)
  assets/icon_foreground.png – 1024×1024 graphic only on transparent background
                               (used for Android adaptive icon foreground layer)
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

DRAW_SIZE  = 2048   # internal render resolution (2× for natural anti-aliasing)
FINAL_SIZE = 1024   # exported resolution

# ── Palette ──────────────────────────────────────────────────────────────────
BG_TL      = (58,  18, 108)   # #3A126C – vivid purple  (top-left)
BG_BR      = (11,  22,  50)   # #0B1632 – deep navy     (bottom-right)
GLOW_COL   = (130, 50, 220, 60)
SPINE_COL  = (200, 170, 255, 255)
PAGE_L     = (255, 255, 255, 250)
PAGE_R     = (245, 240, 255, 250)
LINE_COL   = (158, 120, 210, 150)
WAVE_WHITE = 255
WAVE_ALPHA = (230, 170, 110)   # alpha per wave ring (inner → outer)


# ── Helpers ──────────────────────────────────────────────────────────────────
def draw_star(draw, cx, cy, outer_r, inner_r, n=4,
              color=(255, 210, 80, 220)):
    """Draw an n-pointed star centred at (cx, cy)."""
    pts = []
    for i in range(n * 2):
        angle = math.radians(i * 180 / n - 90)
        r = outer_r if i % 2 == 0 else inner_r
        pts.append((cx + r * math.cos(angle),
                    cy + r * math.sin(angle)))
    draw.polygon(pts, fill=color)


def gradient_background(size):
    """Diagonal purple→navy gradient as an RGBA Image."""
    yt = np.linspace(0, 1, size).reshape(-1, 1)
    xt = np.linspace(0, 1, size).reshape(1, -1)
    t  = (yt + xt) / 2
    r = (BG_TL[0] * (1 - t) + BG_BR[0] * t).astype(np.uint8)
    g = (BG_TL[1] * (1 - t) + BG_BR[1] * t).astype(np.uint8)
    b = (BG_TL[2] * (1 - t) + BG_BR[2] * t).astype(np.uint8)
    arr = np.stack([r, g, b], axis=2)
    return Image.fromarray(arr, 'RGB').convert('RGBA')


def add_glow(base, size):
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    gd   = ImageDraw.Draw(glow)
    c    = size // 2
    gd.ellipse([c - 650, c - 650, c + 650, c + 650], fill=GLOW_COL)
    glow = glow.filter(ImageFilter.GaussianBlur(280))
    return Image.alpha_composite(base, glow)


def draw_book_and_waves(base, size):
    """Draw open book + rising audio waves onto *base* (RGBA Image)."""
    S  = size
    bx = S // 2           # horizontal centre
    by = S // 2 + 200     # book vertical centre  (lower half)
    bw = 520              # half-width of open book (pages)
    bh = 420              # book height
    sw = 54               # spine width
    sk = 32               # perspective skew

    # ── Drop shadow ──────────────────────────────────────────────────────────
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse([bx - bw + 60, by + bh // 2 - 10,
                bx + bw - 60, by + bh // 2 + 90],
               fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(45))
    base   = Image.alpha_composite(base, shadow)

    draw = ImageDraw.Draw(base)

    # ── Left page ────────────────────────────────────────────────────────────
    draw.polygon([
        (bx - bw,      by + bh // 2 + sk),
        (bx - sw // 2, by + bh // 2),
        (bx - sw // 2, by - bh // 2),
        (bx - bw + sk, by - bh // 2 - sk),
    ], fill=PAGE_L)

    # Fold / edge shadow on left outer edge
    draw.polygon([
        (bx - bw,          by + bh // 2 + sk),
        (bx - bw + 22,     by + bh // 2 + sk - 6),
        (bx - bw + sk + 4, by - bh // 2 - sk + 6),
        (bx - bw + sk,     by - bh // 2 - sk),
    ], fill=(215, 200, 240, 190))

    # ── Right page ───────────────────────────────────────────────────────────
    draw.polygon([
        (bx + sw // 2, by + bh // 2),
        (bx + bw,      by + bh // 2 + sk),
        (bx + bw - sk, by - bh // 2 - sk),
        (bx + sw // 2, by - bh // 2),
    ], fill=PAGE_R)

    # ── Spine ────────────────────────────────────────────────────────────────
    draw.rectangle([bx - sw // 2, by - bh // 2,
                    bx + sw // 2, by + bh // 2],
                   fill=SPINE_COL)

    # ── Text lines ───────────────────────────────────────────────────────────
    row_fracs_l = [0.92, 0.88, 0.55, 0.90, 0.75]
    row_fracs_r = [0.88, 0.60, 0.92, 0.80, 0.88]
    for i in range(5):
        yl  = by - 158 + i * 82
        lh  = 20                         # line height
        # left
        xl1 = bx - bw + 80
        xl2 = bx - sw // 2 - 50
        w   = int((xl2 - xl1) * row_fracs_l[i])
        draw.rectangle([xl1, yl, xl1 + w, yl + lh], fill=LINE_COL)
        # right
        xr1 = bx + sw // 2 + 50
        xr2 = bx + bw - 80
        w   = int((xr2 - xr1) * row_fracs_r[i])
        draw.rectangle([xr1, yl, xr1 + w, yl + lh], fill=LINE_COL)

    # ── Audio waves (arcs opening upward, emanating from book) ───────────────
    # Pillow arc angles: 0°=right, 90°=down, 180°=left, 270°=up
    # start=205, end=335 → top arc opening upward (≈ 130° span centred at 270°)
    wcx = bx
    wcy = by - bh // 2 + 30   # anchor just inside the book's top edge

    specs = [
        (250, WAVE_ALPHA[0], 24),   # inner – brightest, thickest
        (390, WAVE_ALPHA[1], 19),   # mid
        (530, WAVE_ALPHA[2], 14),   # outer – faintest
    ]
    for radius, base_alpha, lw in specs:
        for w in range(lw):
            r  = radius + w - lw // 2
            bb = [wcx - r, wcy - r, wcx + r, wcy + r]
            a  = max(10, base_alpha - w * 6)
            draw.arc(bb, start=205, end=335,
                     fill=(WAVE_WHITE, WAVE_WHITE, WAVE_WHITE, a))

    # ── AI sparkle (top-right quadrant) ─────────────────────────────────────
    draw_star(draw,
              cx=bx + bw - 60,
              cy=by - bh // 2 - 210,
              outer_r=58, inner_r=22, n=4,
              color=(255, 215, 80, 225))
    # tiny companion sparkle
    draw_star(draw,
              cx=bx - bw + 130,
              cy=by - bh // 2 - 120,
              outer_r=32, inner_r=12, n=4,
              color=(255, 215, 80, 180))

    return base


# ── Full icon (background + graphic) ─────────────────────────────────────────
def build_full_icon():
    S    = DRAW_SIZE
    base = gradient_background(S)
    base = add_glow(base, S)
    base = draw_book_and_waves(base, S)
    return base.convert('RGB').resize((FINAL_SIZE, FINAL_SIZE), Image.LANCZOS)


# ── Foreground-only icon (transparent bg, for Android adaptive layer) ─────────
def build_foreground_icon():
    S    = DRAW_SIZE
    base = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    base = draw_book_and_waves(base, S)
    return base.resize((FINAL_SIZE, FINAL_SIZE), Image.LANCZOS)


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    os.makedirs('assets/images', exist_ok=True)

    full = build_full_icon()
    full.save('assets/icon.png')
    print('✓  assets/icon.png')

    fg = build_foreground_icon()
    fg.save('assets/icon_foreground.png')
    print('✓  assets/icon_foreground.png')
