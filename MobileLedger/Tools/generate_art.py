"""Generates the painted-parchment UI textures for the Mobile Ledger UI.

Run from the project root:  python3 MobileLedger/Tools/generate_art.py
Needs Pillow + numpy. Everything is procedural so the art can be re-tuned
(colours, sizes) and regenerated. Output goes to MobileLedger/Art/.
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Art")
os.makedirs(OUT, exist_ok=True)

INK = (58, 40, 22)
PARCH = (243, 228, 194)
CREAM = (250, 242, 220)
WAX = (163, 38, 42)
GOLD = (212, 168, 79)
SS = 3  # supersampling for anti-aliased shapes


# ----------------------------------------------------------------- helpers

def noise(w, h, scale, octaves=4, seed=0, stretch=(1.0, 1.0)):
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w), np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        gw = max(2, int(w / scale * (2 ** o) / stretch[0]) + 2)
        gh = max(2, int(h / scale * (2 ** o) / stretch[1]) + 2)
        grid = (rng.random((gh, gw)) * 255).astype(np.uint8)
        layer = np.asarray(Image.fromarray(grid).resize((w, h), Image.BICUBIC), np.float32) / 255.0
        acc += layer * amp
        total += amp
        amp *= 0.5
    acc /= total
    acc = (acc - acc.min()) / max(1e-6, acc.max() - acc.min())
    return acc


def rrect_mask(w, h, r, inset=0):
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [inset * SS, inset * SS, (w - inset) * SS - 1, (h - inset) * SS - 1], r * SS, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def ellipse_mask(w, h, box):
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).ellipse([v * SS for v in box], fill=255)
    return m.resize((w, h), Image.LANCZOS)


def poly_mask(w, h, pts):
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).polygon([(x * SS, y * SS) for x, y in pts], fill=255)
    return m.resize((w, h), Image.LANCZOS)


def solid(w, h, col):
    return Image.new("RGBA", (w, h), col + (255,) if len(col) == 3 else col)


def tint_field(w, h, base, var, seed, scale=60, octaves=5):
    """Colour field = base modulated by noise (painterly mottling)."""
    n = noise(w, h, scale, octaves, seed)
    arr = np.zeros((h, w, 3), np.float32)
    for i in range(3):
        arr[..., i] = base[i] * (1.0 - var / 2 + var * n)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def paste_masked(dst, src, mask):
    dst.paste(src, (0, 0), mask)
    return dst


def outline(mask, width, col, blur=0.0):
    """Outline ring from a mask."""
    grown = mask.filter(ImageFilter.MaxFilter(width * 2 + 1))
    ring = ImageChops.subtract(grown, mask)
    if blur:
        ring = ring.filter(ImageFilter.GaussianBlur(blur))
    layer = Image.new("RGBA", mask.size, col + (0,))
    layer.putalpha(ring)
    return layer, grown


def inner_burn(mask, radius, col, strength):
    """Darkened, burnt-looking edge inside a mask."""
    inv = ImageChops.invert(mask).filter(ImageFilter.GaussianBlur(radius))
    a = ImageChops.multiply(inv, mask)
    a = a.point(lambda v: int(min(255, v * strength)))
    layer = Image.new("RGBA", mask.size, col + (0,))
    layer.putalpha(a)
    return layer


def speckle(img, mask, seed, count, col, alpha=60):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img, "RGBA")
    w, h = img.size
    for _ in range(count):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if mask.getpixel((x, y)) < 200:
            continue
        r = rnd.choice([0.6, 0.8, 1.0, 1.4])
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (rnd.randrange(alpha // 3, alpha),))


def drop_shadow(img, offset=(0, 6), blur=6, alpha=90, pad=0):
    a = img.split()[3]
    sh = Image.new("RGBA", img.size, (40, 24, 10, 0))
    sa = a.point(lambda v: int(v * alpha / 255))
    sh.putalpha(sa)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base = Image.new("RGBA", img.size, (0, 0, 0, 0))
    base.alpha_composite(sh, offset)
    base.alpha_composite(img)
    return base


def save(img, name):
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vgrad(w, h, top, bottom):
    arr = np.zeros((h, w, 3), np.float32)
    for y in range(h):
        t = y / max(1, h - 1)
        arr[y, :, :] = np.array(top) * (1 - t) + np.array(bottom) * t
    return Image.fromarray(arr.astype(np.uint8), "RGB").convert("RGBA")


# ----------------------------------------------------------------- parchment

def parchment_panel(name, w, h, base, r, seed, burn=0.9, border=3, pad=10, ragged=0.0):
    W, H = w + pad * 2, h + pad * 2
    mask = Image.new("L", (W, H), 0)
    mask.paste(rrect_mask(w, h, r), (pad, pad))
    if ragged:
        n = noise(W, H, 12, 3, seed + 7)
        edge = mask.filter(ImageFilter.GaussianBlur(2.2))
        arr = np.asarray(edge, np.float32) / 255.0
        arr = np.clip((arr - 0.5 + (n - 0.5) * ragged) * 8 + 0.5, 0, 1)
        mask = Image.fromarray((arr * 255).astype(np.uint8))
    paper = tint_field(W, H, base, 0.10, seed, 90, 6)
    fine = noise(W, H, 6, 2, seed + 3)
    parr = np.asarray(paper, np.float32)
    parr[..., :3] *= (0.97 + 0.06 * fine)[..., None]
    paper = Image.fromarray(np.clip(parr, 0, 255).astype(np.uint8), "RGBA")
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    img.paste(paper, (0, 0), mask)
    img.alpha_composite(inner_burn(mask, 16, (150, 98, 46), burn))
    img.alpha_composite(inner_burn(mask, 4, (120, 76, 34), 0.5))
    if border:
        ring, _ = outline(mask, border, INK)
        rarr = np.asarray(ring).copy()
        rarr[..., 3] = (rarr[..., 3] * (0.75 + 0.25 * noise(W, H, 20, 2, seed + 9))).astype(np.uint8)
        img.alpha_composite(Image.fromarray(rarr, "RGBA"))
    img = drop_shadow(img, (0, 5), 5, 110)
    save(img, name)


def page_background():
    w, h = 720, 1280
    paper = tint_field(w, h, PARCH, 0.12, 11, 160, 6)
    img = paper
    m = Image.new("L", (w, h), 255)
    img.alpha_composite(inner_burn(m.crop((0, 0, w, h)).point(lambda v: v), 1, (0, 0, 0), 0))
    vig = Image.new("L", (w, h), 0)
    ImageDraw.Draw(vig).rectangle([0, 0, w, h], fill=0)
    edge = Image.new("L", (w, h), 255)
    ImageDraw.Draw(edge).rounded_rectangle([40, 40, w - 40, h - 40], 60, fill=0)
    edge = edge.filter(ImageFilter.GaussianBlur(60))
    layer = Image.new("RGBA", (w, h), (140, 92, 44, 0))
    layer.putalpha(edge.point(lambda v: int(v * 0.55)))
    img.alpha_composite(layer)
    speckle(img, Image.new("L", (w, h), 255), 5, 260, (130, 90, 50), 22)
    save(img, "page_bg.png")


# ----------------------------------------------------------------- wood

def wood(name, w, h, seed, base=(139, 90, 43), plank_h=None, border=True):
    grain = noise(w, h, 40, 5, seed, stretch=(8.0, 0.4))
    streak = noise(w, h, 6, 3, seed + 1, stretch=(14.0, 0.5))
    arr = np.zeros((h, w, 4), np.float32)
    shade = 0.78 + 0.32 * grain + 0.12 * (streak - 0.5)
    for i in range(3):
        arr[..., i] = base[i] * shade
    arr[..., 3] = 255
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(seed)
    if plank_h:
        for y in range(plank_h, h, plank_h):
            d.line([(0, y), (w, y)], fill=(52, 32, 14, 220), width=3)
            d.line([(0, y + 2), (w, y + 2)], fill=(200, 150, 90, 70), width=1)
    d.line([(0, 1), (w, 1)], fill=(214, 160, 100, 120), width=2)
    if border:
        d.line([(0, h - 2), (w, h - 2)], fill=INK + (255,), width=4)
        d.line([(0, 0), (w, 0)], fill=INK + (255,), width=3)
    save(img, name)


# ----------------------------------------------------------------- buttons

def button(name, top, bottom, w=160, h=84, r=18, seed=1, grainy=False, disabled=False):
    pad = 6
    W, H = w, h + pad
    mask = Image.new("L", (W, H), 0)
    mask.paste(rrect_mask(w, h, r), (0, 0))
    body = vgrad(W, H, top, bottom)
    if grainy:
        g = noise(W, H, 30, 4, seed, stretch=(6.0, 0.5))
        barr = np.asarray(body, np.float32)
        barr[..., :3] *= (0.85 + 0.3 * g)[..., None]
        body = Image.fromarray(np.clip(barr, 0, 255).astype(np.uint8), "RGBA")
    else:
        n = noise(W, H, 24, 3, seed)
        barr = np.asarray(body, np.float32)
        barr[..., :3] *= (0.95 + 0.1 * n)[..., None]
        body = Image.fromarray(np.clip(barr, 0, 255).astype(np.uint8), "RGBA")
    shadow = Image.new("L", (W, H), 0)
    shadow.paste(rrect_mask(w, h, r), (0, pad))
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh = Image.new("RGBA", (W, H), (40, 22, 8, 0))
    sh.putalpha(shadow.point(lambda v: int(v * 0.85)))
    img.alpha_composite(sh)
    img.paste(body, (0, 0), mask)
    # bevel: light top rim, dark bottom rim
    hi = Image.new("L", (W, H), 0)
    hi.paste(rrect_mask(w - 10, h // 2, r - 6), (5, 4))
    hi = ImageChops.multiply(hi, ImageChops.invert(hi.filter(ImageFilter.GaussianBlur(3))))
    hl = Image.new("RGBA", (W, H), (255, 255, 240, 0))
    hl.putalpha(hi.point(lambda v: int(min(255, v * 0.9 * (0.5 if disabled else 1)))))
    img.alpha_composite(hl)
    img.alpha_composite(inner_burn(mask, 5, (20, 10, 0), 0.55))
    ring, _ = outline(mask, 3, INK)
    img.alpha_composite(ring)
    save(img, name)


# ----------------------------------------------------------------- seals, ribbons, banners

def wax_seal(name, size=160, ribbon=False, seed=3, col=WAX):
    W, H = size, int(size * (1.45 if ribbon else 1.0))
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cx, cy, R = W / 2, size / 2, size * 0.40
    if ribbon:
        for side in (-1, 1):
            x0 = cx + side * R * 0.18
            pts = [(x0 - 15, cy), (x0 + 15, cy), (x0 + side * 22 + 14, H - 6), (x0 + side * 22, H - 22), (x0 + side * 22 - 14, H - 6)]
            m = poly_mask(W, H, pts)
            rib = vgrad(W, H, (150, 30, 34), (110, 18, 22))
            img.paste(rib, (0, 0), m)
            ring, _ = outline(m, 2, INK)
            img.alpha_composite(ring)
    rnd = random.Random(seed)
    pts = []
    for i in range(48):
        a = i / 48 * math.tau
        rr = R * (1 + 0.06 * math.sin(a * 5 + seed) + rnd.uniform(-0.03, 0.03))
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    m = poly_mask(W, H, pts)
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt((xx - (cx - R * 0.3)) ** 2 + (yy - (cy - R * 0.35)) ** 2) / (R * 1.9)
    light = np.clip(1.25 - d, 0.55, 1.25)
    arr = np.zeros((H, W, 4), np.float32)
    for i in range(3):
        arr[..., i] = col[i] * light
    arr[..., 3] = 255
    body = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    img.paste(body, (0, 0), m)
    dr = ImageDraw.Draw(img, "RGBA")
    r2 = R * 0.66
    dr.ellipse([cx - r2 - 2, cy - r2 + 2, cx + r2 - 2, cy + r2 + 2], outline=(90, 10, 14, 200), width=5)
    dr.ellipse([cx - r2 + 1, cy - r2 + 1, cx + r2 + 1, cy + r2 + 1], outline=(230, 120, 110, 120), width=2)
    # emblem: a little star
    star = []
    for i in range(16):
        a = -math.pi / 2 + i * math.pi / 8
        rr = r2 * (0.62 if i % 2 == 0 else 0.26)
        star.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    dr.polygon(star, fill=(120, 16, 20, 230))
    dr.polygon([(x + 1.5, y + 1.5) for x, y in star], outline=(235, 140, 120, 90))
    ring, _ = outline(m, 2, (60, 8, 10))
    img.alpha_composite(ring)
    img = drop_shadow(img, (2, 4), 3, 120)
    save(img, name)


def ribbon_bookmark(name, w=46, h=86):
    pts = [(3, 0), (w - 3, 0), (w - 3, h - 2), (w / 2, h - 18), (3, h - 2)]
    m = poly_mask(w, h, pts)
    body = Image.new("RGBA", (w, h))
    arr = np.zeros((h, w, 4), np.float32)
    for x in range(w):
        t = x / (w - 1)
        s = 1.15 - 0.45 * abs(t - 0.35)
        arr[:, x, :3] = np.array(WAX) * s
    arr[..., 3] = 255
    body = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.paste(body, (0, 0), m)
    d = ImageDraw.Draw(img, "RGBA")
    d.line([(9, 0), (9, h - 8)], fill=GOLD + (200,), width=2)
    d.line([(w - 9, 0), (w - 9, h - 8)], fill=GOLD + (200,), width=2)
    ring, _ = outline(m, 2, INK)
    img.alpha_composite(ring)
    save(img, name)


def scroll_banner(name, w=620, h=112):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    roll = 54
    body_mask = Image.new("L", (w, h), 0)
    body_mask.paste(rrect_mask(w - roll * 2 + 20, h - 26, 8), (roll - 10, 13))
    paper = tint_field(w, h, (246, 232, 196), 0.10, 21, 70)
    yy = np.linspace(0, 1, h)
    shade = 1.06 - 0.22 * np.abs(yy - 0.42) * 2
    parr = np.asarray(paper, np.float32)
    parr[..., :3] *= shade[:, None, None]
    paper = Image.fromarray(np.clip(parr, 0, 255).astype(np.uint8), "RGBA")
    # rolled ends (drawn first so the body overlaps their inner edge)
    for side in (0, 1):
        x0 = 4 if side == 0 else w - roll - 4
        m = Image.new("L", (w, h), 0)
        m.paste(rrect_mask(roll, h - 4, 22), (x0, 2))
        rollimg = tint_field(w, h, (226, 202, 152), 0.12, 30 + side, 40)
        rarr = np.asarray(rollimg, np.float32)
        xs = np.linspace(0, 1, w)
        sh = 0.75 + 0.4 * np.sin(np.clip((xs * w - x0) / roll, 0, 1) * math.pi)
        rarr[..., :3] *= sh[None, :, None]
        rollimg = Image.fromarray(np.clip(rarr, 0, 255).astype(np.uint8), "RGBA")
        img.paste(rollimg, (0, 0), m)
        ring, _ = outline(m, 3, INK)
        img.alpha_composite(ring)
        d = ImageDraw.Draw(img, "RGBA")
        cxr = x0 + roll / 2
        d.ellipse([cxr - 10, h / 2 - 16, cxr + 10, h / 2 + 16], outline=(110, 74, 34, 200), width=3)
    img.paste(paper, (0, 0), body_mask)
    img.alpha_composite(inner_burn(body_mask, 10, (160, 108, 52), 0.8))
    ring, _ = outline(body_mask, 3, INK)
    img.alpha_composite(ring)
    img = drop_shadow(img, (0, 5), 4, 120)
    save(img, name)


# ----------------------------------------------------------------- slots and frames

def dashed_slot(name, s=120, r=16):
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    m = rrect_mask(s - 8, s - 8, r)
    fill = tint_field(s - 8, s - 8, (236, 220, 182), 0.08, 5, 30)
    inner = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    inner.paste(fill, (4, 4), m)
    img.alpha_composite(inner)
    d = ImageDraw.Draw(img, "RGBA")
    # dashed rounded border: draw dashes along the rounded rect perimeter
    x0, y0, x1, y1 = 5, 5, s - 6, s - 6
    seg, gap = 10, 7
    def dash_line(p, q):
        L = math.dist(p, q)
        n = int(L // (seg + gap)) + 1
        for i in range(n):
            a = i * (seg + gap) / L
            b = min(1, (i * (seg + gap) + seg) / L)
            d.line([lerp(p, q, a), lerp(p, q, b)], fill=(120, 90, 54, 255), width=3)
    dash_line((x0 + r, y0), (x1 - r, y0))
    dash_line((x0 + r, y1), (x1 - r, y1))
    dash_line((x0, y0 + r), (x0, y1 - r))
    dash_line((x1, y0 + r), (x1, y1 - r))
    for cx, cy, a0 in ((x0 + r, y0 + r, 180), (x1 - r, y0 + r, 270), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90)):
        d.arc([cx - r, cy - r, cx + r, cy + r], a0 + 10, a0 + 80, fill=(120, 90, 54, 255), width=3)
    save(img, name)


def gold_ring(draw_img, cx, cy, rx, ry, width):
    W, H = draw_img.size
    outer = ellipse_mask(W, H, [cx - rx, cy - ry, cx + rx, cy + ry])
    inner = ellipse_mask(W, H, [cx - rx + width, cy - ry + width, cx + rx - width, cy + ry - width])
    ring = ImageChops.subtract(outer, inner)
    yy, xx = np.mgrid[0:H, 0:W]
    ang = np.arctan2(yy - cy, xx - cx)
    shade = 0.82 + 0.28 * np.cos(ang + 2.2)
    arr = np.zeros((H, W, 4), np.float32)
    for i in range(3):
        arr[..., i] = GOLD[i] * shade
    arr[..., 3] = 255
    gold = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    draw_img.paste(gold, (0, 0), ring)
    r1, _ = outline(outer, 2, INK)
    draw_img.alpha_composite(r1)
    inner_line = ImageChops.subtract(inner.filter(ImageFilter.MaxFilter(5)), inner)
    l = Image.new("RGBA", (W, H), INK + (0,))
    l.putalpha(inner_line)
    draw_img.alpha_composite(l)
    d = ImageDraw.Draw(draw_img, "RGBA")
    d.ellipse([cx - rx + width / 2 - 1, cy - ry + width / 2 - 1, cx + rx - width / 2 + 1, cy + ry - width / 2 + 1], outline=(255, 236, 170, 110), width=1)


def leaf(d, x, y, ang, L, col=(92, 138, 58)):
    ca, sa = math.cos(ang), math.sin(ang)
    pts = []
    for i in range(13):
        t = i / 12
        wdt = math.sin(t * math.pi) * L * 0.32
        pts.append((x + ca * L * t - sa * wdt, y + sa * L * t + ca * wdt))
    for i in range(12, -1, -1):
        t = i / 12
        wdt = math.sin(t * math.pi) * L * 0.32
        pts.append((x + ca * L * t + sa * wdt, y + sa * L * t - ca * wdt))
    d.polygon(pts, fill=col + (255,), outline=(40, 64, 26, 255))
    d.line([(x, y), (x + ca * L * 0.85, y + sa * L * 0.85)], fill=(60, 96, 38, 200), width=1)


def flower(d, x, y, r, col=(250, 236, 240)):
    for i in range(5):
        a = i / 5 * math.tau
        px, py = x + math.cos(a) * r, y + math.sin(a) * r
        d.ellipse([px - r * 0.8, py - r * 0.8, px + r * 0.8, py + r * 0.8], fill=col + (255,), outline=(120, 90, 100, 255))
    d.ellipse([x - r * 0.5, y - r * 0.5, x + r * 0.5, y + r * 0.5], fill=(232, 186, 60, 255))


def vine(d, pts, seed, leaves=8, flowers=2):
    rnd = random.Random(seed)
    d.line(pts, fill=(70, 98, 44, 255), width=3, joint="curve")
    for i in range(leaves):
        j = rnd.randrange(1, len(pts) - 1)
        x, y = pts[j]
        px, py = pts[j - 1]
        ang = math.atan2(y - py, x - px) + rnd.choice([-1, 1]) * rnd.uniform(0.6, 1.2)
        leaf(d, x, y, ang, rnd.uniform(11, 17), rnd.choice([(92, 138, 58), (110, 152, 66), (78, 120, 50)]))
    for i in range(flowers):
        x, y = pts[rnd.randrange(len(pts))]
        flower(d, x + rnd.uniform(-4, 4), y + rnd.uniform(-4, 4), rnd.uniform(3.5, 5), rnd.choice([(250, 236, 240), (240, 190, 210), (250, 226, 150)]))


def curve(p0, p1, p2, n=24):
    return [(((1 - t) ** 2) * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             ((1 - t) ** 2) * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in [i / (n - 1) for i in range(n)]]


def oval_frame(name, w=300, h=360):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx, cy = w / 2, h / 2 + 4
    rx, ry = w / 2 - 26, h / 2 - 30
    gold_ring(img, cx, cy, rx, ry, 16)
    d = ImageDraw.Draw(img, "RGBA")
    vine(d, curve((cx - 40, h - 14), (18, h - 30), (14, cy + 20)), 4, 9, 2)
    vine(d, curve((cx + 40, h - 14), (w - 18, h - 30), (w - 14, cy + 30)), 5, 9, 2)
    vine(d, curve((cx - 60, 22), (cx - 10, 2), (cx + 40, 18)), 6, 5, 1)
    # gem at the top
    gx, gy = cx, cy - ry + 2
    d.ellipse([gx - 13, gy - 15, gx + 13, gy + 15], fill=GOLD + (255,), outline=INK + (255,), width=2)
    d.ellipse([gx - 8, gy - 10, gx + 8, gy + 10], fill=(70, 120, 190, 255), outline=INK + (255,), width=2)
    d.ellipse([gx - 4, gy - 7, gx, gy - 2], fill=(220, 240, 255, 220))
    img = drop_shadow(img, (0, 4), 4, 110)
    save(img, name)


def circle_slot(name, s=200, filled=False):
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    c = s / 2
    R = s / 2 - 10
    if not filled:
        m = ellipse_mask(s, s, [c - R, c - R, c + R, c + R])
        yy, xx = np.mgrid[0:s, 0:s]
        dd = np.sqrt((xx - c * 0.8) ** 2 + (yy - c * 0.75) ** 2) / R
        arr = np.zeros((s, s, 4), np.float32)
        base = np.array([72, 128, 52])
        arr[..., :3] = base * np.clip(1.25 - 0.45 * dd, 0.6, 1.25)[..., None]
        arr[..., 3] = 255
        img.paste(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA"), (0, 0), m)
        img.alpha_composite(inner_burn(m, 10, (20, 40, 10), 0.8))
    gold_ring(img, c, c, R + 2, R + 2, 12)
    img = drop_shadow(img, (0, 5), 4, 110)
    save(img, name)


def flourish(name, w=150, h=34, flip=False):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    y = h / 2
    pts = curve((8, y + 6), (60, y - 10), (w - 4, y))
    d.line(pts, fill=(96, 120, 52, 255), width=3, joint="curve")
    # little spiral at the outer end
    sp = []
    for i in range(30):
        a = i / 29 * math.tau * 1.15
        r = 8 * (1 - i / 34)
        sp.append((14 + math.cos(a + math.pi) * r, y + 2 + math.sin(a + math.pi) * r))
    d.line(sp, fill=(96, 120, 52, 255), width=2, joint="curve")
    leaf(d, 50, y - 3, -2.4, 13)
    leaf(d, 74, y - 2, 0.9, 12)
    leaf(d, 100, y - 1, -2.0, 11)
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    save(img, name)


def sprig(name, w=170, h=120, seed=1, flip=False):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    vine(d, curve((6, h - 8), (40, 20), (w - 10, 14)), seed, 10, 3)
    vine(d, curve((10, h - 10), (70, h - 30), (w - 30, h - 50)), seed + 1, 6, 1)
    if flip:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    save(img, name)


# ----------------------------------------------------------------- painted quest scenes

def soft(img, r):
    return img.filter(ImageFilter.GaussianBlur(r))


def scene_base(w, h, sky_top, sky_bottom, seed):
    img = vgrad(w, h, sky_top, sky_bottom)
    d = ImageDraw.Draw(img, "RGBA")
    rnd = random.Random(seed)
    clouds = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds, "RGBA")
    for _ in range(4):
        x, y = rnd.uniform(0, w), rnd.uniform(10, h * 0.35)
        for k in range(4):
            r = rnd.uniform(14, 26)
            cd.ellipse([x + k * 18 - r, y - r * 0.6, x + k * 18 + r, y + r * 0.6], fill=(255, 255, 255, 150))
    img.alpha_composite(soft(clouds, 6))
    return img


def hill(w, h, y0, amp, col, seed, blur=0.0, tex=0.12):
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rnd = random.Random(seed)
    ph = rnd.uniform(0, 6)
    pts = [(0, h)]
    for x in range(0, w + 8, 8):
        y = y0 - amp * (0.6 * math.sin(x / w * math.pi * 1.3 + ph) + 0.4 * math.sin(x / w * 7 + ph * 2))
        pts.append((x, y))
    pts.append((w, h))
    m = poly_mask(w, h, pts)
    fill = tint_field(w, h, col, tex * 2, seed, 30)
    layer.paste(fill, (0, 0), m)
    edge, _ = outline(m, 1, (50, 60, 30))
    layer.alpha_composite(edge)
    return soft(layer, blur) if blur else layer


def pine(d, x, y, hgt, col=(54, 92, 50)):
    wdt = hgt * 0.42
    for k in range(3):
        top = y - hgt + k * hgt * 0.22
        bot = y - hgt * 0.25 + k * hgt * 0.25
        d.polygon([(x, top), (x - wdt * (0.6 + k * 0.2), bot), (x + wdt * (0.6 + k * 0.2), bot)], fill=col + (255,), outline=(30, 52, 28, 255))
        d.polygon([(x, top + 3), (x + wdt * (0.55 + k * 0.2), bot - 1), (x + 2, bot - 1)], fill=tuple(min(255, int(c * 1.25)) for c in col) + (255,))
    d.rectangle([x - 2, y - 3, x + 2, y + 3], fill=(90, 60, 30, 255))


def tower(d, x, y, tw, th, roof_col, stone=(196, 186, 168)):
    d.rectangle([x - tw / 2, y - th, x + tw / 2, y], fill=stone + (255,), outline=INK + (255,), width=2)
    d.rectangle([x, y - th, x + tw / 2, y], fill=tuple(int(c * 0.86) for c in stone) + (255,))
    d.rectangle([x - tw / 2, y - th, x + tw / 2, y], outline=INK + (255,), width=2)
    d.polygon([(x - tw / 2 - 4, y - th), (x + tw / 2 + 4, y - th), (x, y - th - tw * 1.3)], fill=roof_col + (255,), outline=INK + (255,))
    d.polygon([(x, y - th - tw * 1.3), (x + tw / 2 + 4, y - th), (x + 1, y - th)], fill=tuple(int(c * 0.75) for c in roof_col) + (255,))
    for k in range(int(th // 22)):
        wy = y - th + 10 + k * 22
        d.rounded_rectangle([x - 3, wy, x + 3, wy + 9], 3, fill=(60, 44, 40, 255))


def finish_scene(img, name, seed):
    w, h = img.size
    tex = noise(w, h, 8, 3, seed)
    arr = np.asarray(img, np.float32)
    arr[..., :3] *= (0.94 + 0.1 * tex)[..., None]
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    img = soft(img, 0.6)
    # watercolour vignette: fade edges into the parchment
    m = Image.new("L", (w, h), 0)
    n = noise(w, h, 22, 3, seed + 4)
    ImageDraw.Draw(m).rounded_rectangle([14, 10, w - 14, h - 10], 40, fill=255)
    m = m.filter(ImageFilter.GaussianBlur(14))
    marr = np.asarray(m, np.float32) / 255.0
    marr = np.clip((marr - 0.25 + (n - 0.5) * 0.35) * 1.9, 0, 1)
    img.putalpha(Image.fromarray((marr * 255).astype(np.uint8)))
    save(img, name)


def scene_castle():
    w, h = 360, 240
    img = scene_base(w, h, (150, 196, 226), (236, 232, 206), 1)
    img.alpha_composite(hill(w, h, 150, 18, (150, 178, 170), 2, 2.0))
    img.alpha_composite(hill(w, h, 196, 22, (128, 170, 82), 3))
    d = ImageDraw.Draw(img, "RGBA")
    d.polygon([(150, 240), (178, 196), (200, 190), (172, 240)], fill=(214, 186, 132, 255))
    cx, base = 186, 176
    d.rectangle([cx - 50, base - 46, cx + 50, base], fill=(190, 178, 158, 255), outline=INK + (255,), width=2)
    for i in range(-50, 51, 12):
        d.rectangle([cx + i - 3, base - 52, cx + i + 3, base - 46], fill=(190, 178, 158, 255), outline=INK + (255,))
    tower(d, cx - 52, base, 22, 70, (170, 50, 46))
    tower(d, cx + 52, base, 22, 64, (60, 96, 150))
    tower(d, cx, base - 30, 30, 70, (170, 50, 46))
    tower(d, cx - 20, base - 20, 14, 40, (60, 96, 150))
    tower(d, cx + 24, base - 20, 14, 46, (170, 50, 46))
    d.rounded_rectangle([cx - 10, base - 22, cx + 10, base], 8, fill=(70, 46, 30, 255), outline=INK + (255,), width=2)
    for x, s in ((40, 46), (62, 34), (300, 50), (326, 38), (280, 30), (90, 28)):
        pine(d, x, 206 + (s % 7), s)
    finish_scene(img, "scene_dungeon.png", 1)


def scene_escort():
    w, h = 360, 240
    img = scene_base(w, h, (162, 204, 228), (240, 232, 204), 7)
    img.alpha_composite(hill(w, h, 140, 16, (140, 172, 160), 8, 2.0))
    img.alpha_composite(hill(w, h, 180, 14, (138, 176, 88), 9))
    d = ImageDraw.Draw(img, "RGBA")
    road = curve((120, 240), (190, 170), (330, 150), 30)
    for wdt, col in ((26, INK), (22, (214, 186, 132))):
        d.line(road, fill=col + (255,), width=wdt, joint="curve")
    # town on the horizon
    for i, x in enumerate((262, 282, 302, 322)):
        hh = 18 + (i % 2) * 8
        d.rectangle([x - 9, 146 - hh, x + 9, 146], fill=(226, 214, 190, 255), outline=INK + (255,))
        d.polygon([(x - 12, 146 - hh), (x + 12, 146 - hh), (x, 132 - hh)], fill=(150, 66, 50, 255), outline=INK + (255,))
    # cart
    cx, cy = 150, 196
    d.polygon([(cx - 46, cy - 26), (cx + 30, cy - 26), (cx + 26, cy - 4), (cx - 42, cy - 4)], fill=(139, 90, 43, 255), outline=INK + (255,))
    d.chord([cx - 48, cy - 66, cx + 30, cy - 6], 180, 360, fill=(246, 234, 206, 255), outline=INK + (255,))
    for k in range(3):
        d.arc([cx - 48 + k * 2, cy - 66, cx + 30 - k * 2, cy - 6], 190 + k * 30, 210 + k * 30, fill=(200, 180, 140, 255), width=2)
    for wx in (cx - 30, cx + 16):
        d.ellipse([wx - 12, cy - 14, wx + 12, cy + 10], fill=(110, 72, 36, 255), outline=INK + (255,), width=2)
        d.ellipse([wx - 3, cy - 5, wx + 3, cy + 1], fill=GOLD + (255,))
    # horse
    hx = cx + 54
    d.ellipse([hx - 20, cy - 34, hx + 16, cy - 12], fill=(120, 80, 50, 255), outline=INK + (255,), width=2)
    d.polygon([(hx + 10, cy - 30), (hx + 22, cy - 52), (hx + 32, cy - 46), (hx + 18, cy - 24)], fill=(120, 80, 50, 255), outline=INK + (255,))
    for lx in (hx - 14, hx - 6, hx + 4, hx + 12):
        d.line([(lx, cy - 16), (lx, cy + 4)], fill=INK + (255,), width=4)
    for x, s in ((40, 44), (70, 30), (330, 40), (24, 28)):
        pine(d, x, 214, s)
    finish_scene(img, "scene_escort.png", 7)


def scene_scout():
    w, h = 360, 240
    img = scene_base(w, h, (150, 196, 230), (236, 236, 214), 12)
    d = ImageDraw.Draw(img, "RGBA")
    for (x, y, s, col) in ((110, 60, 90, (138, 160, 180)), (230, 40, 120, (156, 176, 196)), (320, 80, 70, (132, 154, 174))):
        d.polygon([(x - s, 170), (x, y), (x + s, 170)], fill=col + (255,), outline=INK + (255,))
        d.polygon([(x, y), (x + s, 170), (x + 6, 170)], fill=tuple(int(c * 0.82) for c in col) + (255,))
        d.polygon([(x - s * 0.25, y + (170 - y) * 0.25), (x, y), (x + s * 0.25, y + (170 - y) * 0.25), (x + 6, y + 30), (x - 8, y + 22)], fill=(250, 252, 255, 255), outline=INK + (255,))
    img = Image.alpha_composite(img, soft(Image.new("RGBA", (w, h), (0, 0, 0, 0)), 1))
    img.alpha_composite(hill(w, h, 176, 8, (122, 166, 84), 13))
    d = ImageDraw.Draw(img, "RGBA")
    lake = ellipse_mask(w, h, [70, 178, 300, 222])
    water = vgrad(w, h, (120, 172, 214), (78, 132, 186))
    img.paste(water, (0, 0), lake)
    ring, _ = outline(lake, 2, INK)
    img.alpha_composite(ring)
    d = ImageDraw.Draw(img, "RGBA")
    for k in range(5):
        y = 190 + k * 6
        d.line([(110 + k * 14, y), (150 + k * 14, y)], fill=(230, 244, 255, 150), width=2)
    for x, s in ((26, 52), (52, 40), (316, 56), (340, 42), (290, 34), (80, 30)):
        pine(d, x, 222 + (s % 5), s)
    finish_scene(img, "scene_scout.png", 12)


def scene_intel():
    w, h = 360, 240
    img = scene_base(w, h, (78, 70, 120), (214, 160, 140), 21)
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([270, 30, 306, 66], fill=(250, 238, 196, 255))
    img.alpha_composite(soft(Image.new("RGBA", (w, h)), 0))
    rnd = random.Random(4)
    x = -10
    while x < w + 10:
        bw = rnd.randrange(34, 56)
        bh = rnd.randrange(60, 120)
        top = 220 - bh
        col = rnd.choice([(120, 96, 110), (104, 84, 100), (132, 106, 116)])
        d.rectangle([x, top, x + bw, 240], fill=col + (255,), outline=INK + (255,), width=2)
        d.polygon([(x - 4, top), (x + bw + 4, top), (x + bw / 2, top - bw * 0.6)], fill=(80, 56, 70, 255), outline=INK + (255,))
        for wy in range(top + 12, 220, 22):
            for wx in range(x + 8, x + bw - 8, 14):
                if rnd.random() < 0.55:
                    d.rectangle([wx, wy, wx + 7, wy + 10], fill=(255, 210, 110, 255), outline=INK + (255,))
        x += bw + rnd.randrange(-4, 6)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    gd.ellipse([150, 150, 230, 230], fill=(255, 200, 100, 90))
    img.alpha_composite(soft(glow, 16))
    d = ImageDraw.Draw(img, "RGBA")
    # hooded informant
    d.polygon([(178, 236), (190, 182), (204, 176), (218, 182), (230, 236)], fill=(46, 40, 54, 255), outline=INK + (255,))
    d.ellipse([194, 168, 214, 192], fill=(46, 40, 54, 255), outline=INK + (255,))
    d.line([(232, 236), (232, 196)], fill=INK + (255,), width=3)
    d.rectangle([226, 186, 238, 198], fill=(255, 210, 110, 255), outline=INK + (255,))
    finish_scene(img, "scene_intel.png", 21)


def scene_drake():
    w, h = 360, 240
    img = scene_base(w, h, (120, 40, 40), (232, 150, 96), 31)
    img.alpha_composite(hill(w, h, 196, 10, (96, 80, 70), 32))
    d = ImageDraw.Draw(img, "RGBA")
    for i, x in enumerate(range(30, 340, 36)):
        hh = 22 + (i % 3) * 8
        d.rectangle([x - 12, 210 - hh, x + 12, 214], fill=(214, 196, 170, 255), outline=INK + (255,))
        d.polygon([(x - 15, 210 - hh), (x + 15, 210 - hh), (x, 194 - hh)], fill=(150, 60, 46, 255), outline=INK + (255,))
    bone = (236, 228, 208)
    # wings
    for side in (-1, 1):
        cx = 180
        pts = [(cx + side * 10, 92), (cx + side * 70, 40), (cx + side * 150, 54), (cx + side * 128, 84), (cx + side * 96, 86), (cx + side * 74, 104)]
        d.polygon(pts, fill=(170, 60, 60, 160), outline=INK + (255,))
        for k in (40, 54, 84, 86):
            pass
        d.line([(cx + side * 10, 92), (cx + side * 70, 40), (cx + side * 150, 54)], fill=bone + (255,), width=5)
        d.line([(cx + side * 70, 40), (cx + side * 128, 84)], fill=bone + (255,), width=3)
        d.line([(cx + side * 70, 40), (cx + side * 96, 86)], fill=bone + (255,), width=3)
    # spine + ribs + skull
    spine = curve((120, 116), (180, 70), (250, 106), 20)
    d.line(spine, fill=INK + (255,), width=8, joint="curve")
    d.line(spine, fill=bone + (255,), width=5, joint="curve")
    for i in range(5, 14, 2):
        x, y = spine[i]
        d.arc([x - 10, y - 2, x + 10, y + 26], 200, 340, fill=bone + (255,), width=3)
    sx, sy = 252, 104
    d.polygon([(sx - 8, sy - 12), (sx + 26, sy - 6), (sx + 40, sy + 6), (sx + 18, sy + 12), (sx - 4, sy + 8)], fill=bone + (255,), outline=INK + (255,))
    d.ellipse([sx + 8, sy - 6, sx + 16, sy + 2], fill=(200, 30, 30, 255))
    d.polygon([(sx - 2, sy - 10), (sx - 14, sy - 26), (sx + 6, sy - 12)], fill=bone + (255,), outline=INK + (255,))
    finish_scene(img, "scene_milestone.png", 31)


if __name__ == "__main__":
    page_background()
    parchment_panel("panel_parchment.png", 220, 220, PARCH, 22, 1)
    parchment_panel("card_parchment.png", 220, 220, CREAM, 14, 2, burn=0.7, ragged=0.9)
    parchment_panel("card_ready.png", 220, 220, (232, 240, 210), 14, 2, burn=0.6, ragged=0.9)
    parchment_panel("inset_parchment.png", 140, 140, (233, 214, 170), 12, 3, burn=0.6, border=2, pad=6)
    wood("wood_bar.png", 720, 150, 5, plank_h=None)
    wood("wood_dark.png", 720, 120, 6, base=(112, 70, 34))
    parchment_panel("tab_tile.png", 120, 130, (226, 204, 156), 12, 8, burn=0.9, border=3, pad=6)
    parchment_panel("tab_tile_active.png", 120, 130, (250, 240, 214), 12, 9, burn=0.5, border=3, pad=6)
    ribbon_bookmark("ribbon.png")
    scroll_banner("banner.png")
    wax_seal("seal.png", 150)
    wax_seal("seal_ribbon.png", 150, ribbon=True)
    wax_seal("seal_dark.png", 150, ribbon=True, col=(96, 20, 30))
    button("btn_green.png", (110, 166, 74), (62, 112, 44), seed=1)
    button("btn_green_down.png", (70, 120, 48), (56, 100, 38), seed=1)
    button("btn_red.png", (196, 66, 56), (140, 34, 34), seed=2)
    button("btn_red_down.png", (150, 40, 38), (128, 30, 30), seed=2)
    button("btn_wood.png", (176, 118, 64), (122, 76, 38), seed=3, grainy=True)
    button("btn_wood_down.png", (128, 82, 42), (112, 70, 34), seed=3, grainy=True)
    button("btn_blue.png", (86, 134, 186), (46, 88, 136), seed=4)
    button("btn_blue_down.png", (52, 96, 146), (42, 80, 124), seed=4)
    button("btn_paper.png", (252, 244, 222), (226, 208, 166), seed=5)
    button("btn_paper_down.png", (226, 208, 166), (214, 194, 150), seed=5)
    button("btn_disabled.png", (214, 204, 184), (190, 178, 156), seed=6, disabled=True)
    dashed_slot("slot_dashed.png")
    circle_slot("slot_circle.png")
    circle_slot("slot_ring.png", filled=True)
    oval_frame("frame_oval.png")
    flourish("flourish_l.png")
    flourish("flourish_r.png", flip=True)
    sprig("sprig_l.png", seed=2)
    sprig("sprig_r.png", seed=3, flip=True)
    scene_castle()
    scene_escort()
    scene_scout()
    scene_intel()
    scene_drake()
